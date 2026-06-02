const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/authMiddleware');
const Prescription = require('../models/Prescription');
const MedicineHistory = require('../models/MedicineHistory');

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

// Get Dashboard Stats
router.get('/dashboard-stats', protect, authorize('Patient'), async (req, res) => {
    try {
        const abhaId = req.user.abhaId;
        if (!abhaId) {
            return res.status(400).json({ message: 'User does not have an ABHA ID linked' });
        }
        
        const prescriptions = await Prescription.find({ abhaId });
        
        // Calculate active medicines (unique medicines across all prescriptions)
        const uniqueMedicines = new Set();
        prescriptions.forEach(p => {
            if (p.medicines && Array.isArray(p.medicines)) {
                p.medicines.forEach(m => {
                    if (m.name) uniqueMedicines.add(m.name.toLowerCase().trim());
                });
            }
        });

        res.json({
            activeMedicines: uniqueMedicines.size,
            totalPrescriptions: prescriptions.length
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Log Medicine Taken
router.post('/history', protect, authorize('Patient'), async (req, res) => {
    try {
        const { medicineId, medicineName, takenTime, status } = req.body;
        const abhaId = req.user.abhaId;

        if (!abhaId) {
            return res.status(400).json({ message: 'User does not have an ABHA ID linked' });
        }

        const historyLog = new MedicineHistory({
            patient: req.user._id,
            abhaId,
            medicineId,
            medicineName,
            takenTime: takenTime || new Date(),
            status: status || 'TAKEN'
        });

        await historyLog.save();
        res.status(201).json(historyLog);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get Medicine History
router.get('/history', protect, authorize('Patient'), async (req, res) => {
    try {
        const abhaId = req.user.abhaId;
        if (!abhaId) {
            return res.status(400).json({ message: 'User does not have an ABHA ID linked' });
        }

        const history = await MedicineHistory.find({ abhaId }).sort({ takenTime: -1 });
        res.json(history);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

module.exports = router;
