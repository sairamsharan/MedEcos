const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const Prescription = require('../models/Prescription');
const User = require('../models/User');
const Medicine = require('../models/Medicine');

// Verify Prescription Signature
router.get('/verify-prescription/:id', async (req, res) => {
    try {
        const prescription = await Prescription.findById(req.params.id);

        if (!prescription) {
            return res.status(404).json({ message: 'Prescription not found' });
        }

        if (!prescription.digitalSignature) {
            return res.status(400).json({ message: 'Prescription does not have a digital signature' });
        }

        // Fetch the doctor who signed it to get their public key
        const doctor = await User.findById(prescription.doctorId);

        if (!doctor || !doctor.publicKey) {
            return res.status(404).json({ message: 'Doctor or public key not found for verification' });
        }

        if (!prescription.signaturePayload) {
            return res.status(400).json({ message: 'Prescription does not have a signature payload to verify against.' });
        }
        
        const payload = prescription.signaturePayload;

        // Verify the signature
        const verify = crypto.createVerify('SHA256');
        verify.update(payload);
        verify.end();

        const isAuthentic = verify.verify(doctor.publicKey, prescription.digitalSignature, 'base64');

        res.json({
            prescriptionId: prescription._id,
            isAuthentic: isAuthentic,
            signedBy: doctor.username || 'Unknown Doctor',
            date: prescription.date
        });

    } catch (error) {
        console.error(error);
        if (error.kind === 'ObjectId') {
            return res.status(404).json({ message: 'Invalid Prescription ID format' });
        }
        res.status(500).json({ message: 'Server error during verification' });
    }
});

// Get all prescriptions for a patient by ABHA ID (Public/Pharmacist/Lab view)
router.get('/prescriptions/patient/:abhaId', async (req, res) => {
    try {
        const prescriptions = await Prescription.find({ abhaId: req.params.abhaId }).sort({ date: -1 });
        res.json(prescriptions);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get a single prescription by ID
router.get('/prescriptions/:id', async (req, res) => {
    try {
        const prescription = await Prescription.findById(req.params.id);
        if (!prescription) {
            return res.status(404).json({ message: 'Prescription not found' });
        }
        res.json(prescription);
    } catch (error) {
        console.error(error);
        if (error.kind === 'ObjectId') {
            return res.status(404).json({ message: 'Invalid/not found Prescription ID format' });
        }
        res.status(500).json({ message: 'Server error' });
    }
});

// Get all verified doctors
router.get('/doctors', async (req, res) => {
    try {
        const doctors = await User.find({ role: 'Doctor' }).select('-password -privateKey -aadhaarNumber');
        res.json(doctors);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get all medicines
router.get('/medicines', async (req, res) => {
    try {
        const medicines = await Medicine.find().sort({ name: 1 });
        res.json(medicines);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

module.exports = router;
