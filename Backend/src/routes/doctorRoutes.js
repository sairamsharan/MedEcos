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


module.exports = router;
