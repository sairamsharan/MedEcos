const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/authMiddleware');
const Prescription = require('../models/Prescription');
const User = require('../models/User');

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

// Get Dashboard Stats
router.get('/dashboard-stats', protect, authorize('Doctor'), async (req, res) => {
    try {
        const Appointment = require('../models/Appointment');
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
        
        const uniquePatients = (await Prescription.distinct('abhaId', { doctorId: req.user.id })).length;

        res.json({
            appointmentsToday,
            pendingReports,
            totalPatients: uniquePatients
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

module.exports = router;
