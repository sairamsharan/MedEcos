const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/authMiddleware');
const Prescription = require('../models/Prescription');
const User = require('../models/User');
const Appointment = require('../models/Appointment');

const crypto = require('crypto');

// Create Prescription
router.post('/prescriptions', protect, authorize('Doctor'), async (req, res) => {
    try {
        const { abhaId, diagnosis, medicines, labTests } = req.body;

        if (!abhaId || !diagnosis || !medicines) {
            return res.status(400).json({ message: 'Please provide all required fields' });
        }

        // Fetch the doctor's private key
        const doctor = await User.findById(req.user.id).select('+privateKey');
        if (!doctor || !doctor.privateKey) {
            return res.status(500).json({ message: 'Doctor digital signature key not found' });
        }

        // Create a deterministic payload string
        const payload = JSON.stringify({ abhaId, diagnosis, medicines, labTests });

        // Sign the payload
        const sign = crypto.createSign('SHA256');
        sign.update(payload);
        sign.end();
        const digitalSignature = sign.sign(doctor.privateKey, 'base64');

        const prescription = await Prescription.create({
            abhaId,
            doctorId: req.user.id,
            doctorName: req.user.username || 'Unknown Doctor', // Fallback
            diagnosis,
            medicines,
            labTests,
            digitalSignature
        });

        // Mark the active appointment as Finished
        const appointment = await Appointment.findOne({
            doctorId: req.user.id,
            abhaId: abhaId,
            status: { $in: ['Pending', 'Confirmed'] }
        }).sort({ date: 1 });
        
        if (appointment) {
            appointment.status = 'Finished';
            await appointment.save();
        }

        res.status(201).json(prescription);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Search Patient by ABHA
router.get('/patients/:abhaId', protect, authorize('Doctor'), async (req, res) => {
    try {
        const patient = await User.findOne({ abhaId: req.params.abhaId, role: 'Patient' });
        if (!patient) {
            return res.status(404).json({ message: 'Patient not found' });
        }
        res.json(patient);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Register Patient via ABHA OTP
router.post('/patients/abha-register', protect, authorize('Doctor'), async (req, res) => {
    try {
        const { transactionId, otp, abhaId } = req.body;

        if (!transactionId || !otp || !abhaId) {
            return res.status(400).json({ message: 'All fields are required' });
        }

        const Otp = require('../models/Otp');
        
        // Verify OTP
        let otpDoc = null;
        if (transactionId === 'txn-mock') {
            if (otp !== '123456') {
                return res.status(400).json({ message: 'Invalid OTP' });
            }
        } else {
            otpDoc = await Otp.findOne({ transactionId, abhaId });
            if (!otpDoc || otpDoc.otp !== otp) {
                return res.status(400).json({ message: 'Invalid OTP or transaction expired' });
            }
        }

        // Check if user exists
        let user = await User.findOne({ abhaId });

        if (!user) {
            const MockABDMUser = require('../models/MockABDMUser');
            const abdmData = await MockABDMUser.findOne({ abhaId });
            
            user = await User.create({
                abhaId,
                role: 'Patient',
                username: abdmData ? abdmData.name : `patient_${abhaId.replace(/-/g, '')}`,
                age: abdmData ? abdmData.age : undefined,
                gender: abdmData ? abdmData.gender : undefined,
            });
        }

        if (otpDoc) {
            await Otp.deleteOne({ _id: otpDoc._id });
        }

        // Track this patient in the doctor's document
        const provider = await User.findById(req.user.id);
        if (provider && !provider.patients.includes(abhaId)) {
            provider.patients.push(abhaId);
            await provider.save();
        }

        // Return the patient data
        res.json(user);

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: error.message || 'Server error' });
    }
});
// Get Patient Prescriptions
router.get('/prescriptions/:abhaId', protect, authorize('Doctor'), async (req, res) => {
    try {
        const prescriptions = await Prescription.find({ abhaId: req.params.abhaId }).sort({ date: -1 });
        res.json(prescriptions);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get All Prescriptions written by this Doctor
router.get('/prescriptions', protect, authorize('Doctor'), async (req, res) => {
    try {
        const prescriptions = await Prescription.find({ doctorId: req.user.id }).sort({ date: -1 });
        res.json(prescriptions);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Update Prescription Status and Notes
router.put('/prescriptions/:id/notes', protect, authorize('Doctor'), async (req, res) => {
    try {
        const { status, doctorNotes } = req.body;
        const prescription = await Prescription.findOne({ _id: req.params.id, doctorId: req.user.id });
        
        if (!prescription) return res.status(404).json({ message: 'Prescription not found' });
        
        if (status) prescription.status = status;
        if (doctorNotes !== undefined) prescription.doctorNotes = doctorNotes;
        
        await prescription.save();
        res.json(prescription);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get Doctor's Patients
router.get('/patients', protect, authorize('Doctor'), async (req, res) => {
    try {
        const provider = await User.findById(req.user.id);
        const uniqueAbhaIds = await Prescription.distinct('abhaId', { doctorId: req.user.id });
        const allPatientIds = [...new Set([...uniqueAbhaIds, ...(provider.patients || [])])];
        
        const patients = await User.find({ abhaId: { $in: allPatientIds }, role: 'Patient' });
        res.json(patients);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get Dashboard Stats
router.get('/dashboard-stats', protect, authorize('Doctor'), async (req, res) => {
    try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        const appointmentsToday = await Appointment.countDocuments({ 
            doctorId: req.user.id, 
            date: { $gte: today } 
        });
        
        const pendingReports = await Appointment.countDocuments({ 
            doctorId: req.user.id, 
            status: 'Pending' 
        });
        
        const provider = await User.findById(req.user.id);
        const uniqueAbhaIds = await Prescription.distinct('abhaId', { doctorId: req.user.id });
        const allPatientIds = [...new Set([...uniqueAbhaIds, ...(provider.patients || [])])];

        res.json({
            appointmentsToday,
            pendingReports,
            totalPatients: allPatientIds.length
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get all appointments for a doctor
router.get('/appointments', protect, authorize('Doctor'), async (req, res) => {
    try {
        const appointments = await Appointment.find({ doctorId: req.user.id }).sort({ date: 1 });
        res.json(appointments);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Accept appointment
router.post('/appointments/:id/accept', protect, authorize('Doctor'), async (req, res) => {
    try {
        const appointment = await Appointment.findOne({ _id: req.params.id, doctorId: req.user.id });
        if (!appointment) return res.status(404).json({ message: 'Appointment not found' });
        
        appointment.status = 'Confirmed';
        await appointment.save();
        res.json(appointment);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Reschedule appointment
router.post('/appointments/:id/reschedule', protect, authorize('Doctor'), async (req, res) => {
    try {
        const { rescheduleDate, rescheduleNotes } = req.body;
        if (!rescheduleDate) return res.status(400).json({ message: 'rescheduleDate is required' });

        const appointment = await Appointment.findOne({ _id: req.params.id, doctorId: req.user.id });
        if (!appointment) return res.status(404).json({ message: 'Appointment not found' });
        
        appointment.status = 'RescheduleRequested';
        appointment.rescheduleDate = rescheduleDate;
        appointment.rescheduleNotes = rescheduleNotes;
        await appointment.save();
        res.json(appointment);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Finish appointment
router.post('/appointments/:id/finish', protect, authorize('Doctor'), async (req, res) => {
    try {
        const appointment = await Appointment.findOne({ _id: req.params.id, doctorId: req.user.id });
        if (!appointment) return res.status(404).json({ message: 'Appointment not found' });
        
        appointment.status = 'Finished';
        await appointment.save();
        res.json(appointment);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

module.exports = router;
