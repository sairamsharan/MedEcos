const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/authMiddleware');
const Prescription = require('../models/Prescription');
const User = require('../models/User');
const LabTestOrder = require('../models/LabTestOrder');

// Get Lab Tests for a Patient (Lookup by ABHA ID)
router.get('/patients/:abhaId/lab-tests', protect, authorize('Lab_Tester'), async (req, res) => {
    try {
        const { abhaId } = req.params;
        
        // Find patient
        const patient = await User.findOne({ abhaId, role: 'Patient' });
        if (!patient) {
            return res.status(404).json({ message: 'Patient not found' });
        }

        // Find prescriptions for this patient that contain lab tests
        const prescriptions = await Prescription.find({ 
            abhaId, 
            labTests: { $exists: true, $not: { $size: 0 } }
        }).sort({ date: -1 });

        // Extract and format the lab tests
        const testsToPerform = [];
        prescriptions.forEach(p => {
            if (p.labTests && p.labTests.length > 0) {
                p.labTests.forEach(test => {
                    testsToPerform.push({
                        testName: test,
                        prescriptionId: p._id,
                        doctorName: p.doctorName,
                        datePrescribed: p.date,
                        diagnosis: p.diagnosis,
                    });
                });
            }
        });

        res.json({
            patient: {
                name: patient.username,
                abhaId: patient.abhaId,
                age: patient.age,
                gender: patient.gender,
            },
            tests: testsToPerform
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get Lab Test Orders for this Lab Tester
router.get('/orders', protect, authorize('Lab_Tester'), async (req, res) => {
    try {
        const orders = await LabTestOrder.find({ labTesterId: req.user._id }).sort({ createdAt: -1 });
        res.json(orders);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Update Lab Test Order Status
router.put('/orders/:id/status', protect, authorize('Lab_Tester'), async (req, res) => {
    try {
        const { status } = req.body;
        if (!['Pending', 'In_Progress', 'Completed'].includes(status)) {
            return res.status(400).json({ message: 'Invalid status' });
        }

        const order = await LabTestOrder.findOneAndUpdate(
            { _id: req.params.id, labTesterId: req.user._id },
            { 
                status,
                ...(status === 'Completed' ? { dateCompleted: Date.now() } : {})
            },
            { new: true }
        );

        if (!order) return res.status(404).json({ message: 'Order not found' });

        res.json(order);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

module.exports = router;
