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

        // Fetch existing orders to merge status
        const existingOrders = await LabTestOrder.find({ patientId: patient._id });

        // Extract and format the lab tests
        const testsToPerform = [];
        prescriptions.forEach(p => {
            if (p.labTests && p.labTests.length > 0) {
                p.labTests.forEach(test => {
                    // Find if there's an existing order for this exact test from this prescription
                    const order = existingOrders.find(o => 
                        o.testName === test && 
                        o.prescriptionId?.toString() === p._id.toString()
                    );
                    
                    testsToPerform.push({
                        testName: test,
                        prescriptionId: p._id,
                        doctorName: p.doctorName,
                        datePrescribed: p.date,
                        diagnosis: p.diagnosis,
                        status: order ? order.status : 'Pending',
                        orderId: order ? order._id : null
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

// Process a Lab Test (Create or Update LabTestOrder to In_Progress)
router.post('/patients/:abhaId/process-test', protect, authorize('Lab_Tester'), async (req, res) => {
    try {
        const { abhaId } = req.params;
        const { testName, prescriptionId } = req.body;
        
        if (!testName || !prescriptionId) {
            return res.status(400).json({ message: 'testName and prescriptionId are required' });
        }

        const patient = await User.findOne({ abhaId, role: 'Patient' });
        if (!patient) {
            return res.status(404).json({ message: 'Patient not found' });
        }

        // Check if order already exists
        let order = await LabTestOrder.findOne({
            patientId: patient._id,
            prescriptionId,
            testName
        });

        if (order) {
            if (order.status === 'Completed') {
                return res.status(400).json({ message: 'Test already completed' });
            }
            order.status = 'In_Progress';
            order.labTesterId = req.user._id; // Take ownership
            await order.save();
        } else {
            order = await LabTestOrder.create({
                patientId: patient._id,
                patientName: patient.username || 'Unknown Patient',
                labTesterId: req.user._id,
                testName,
                prescriptionId,
                status: 'In_Progress'
            });
        }

        // Check if the lab tester already provides this test, if not, add it
        const labTester = await User.findById(req.user._id);
        if (labTester && !labTester.labTestsProvided.includes(testName)) {
            labTester.labTestsProvided.push(testName);
            await labTester.save();
        }

        res.json(order);
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
