const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/authMiddleware');
const Prescription = require('../models/Prescription');

// Get My Medical History (Prescriptions)
router.get('/prescriptions', protect, authorize('Patient'), async (req, res) => {
    try {
        const abhaId = req.user.abhaId;
        if (!abhaId) {
            return res.status(400).json({ message: 'User does not have an ABHA ID linked' });
        }

        const prescriptions = await Prescription.find({ abhaId }).sort({ date: -1 });

        // Transform to MedicalHistory format if needed, or just return list
        const medicalHistory = {
            abhaId: abhaId,
            records: prescriptions.map(p => ({
                prescriptionId: p._id,
                doctorName: p.doctorName,
                date: p.date,
                diagnosis: p.diagnosis,
                medicines: p.medicines.map(m => m.name), // Simplifying for view
                fullMedicines: p.medicines // Providing full details too
            }))
        };

        res.json(medicalHistory);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get Profile
router.get('/profile', protect, authorize('Patient'), async (req, res) => {
    res.json(req.user);
});

module.exports = router;
