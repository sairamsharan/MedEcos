const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/authMiddleware');
const Prescription = require('../models/Prescription');
const User = require('../models/User');
const Inventory = require('../models/Inventory');
const abhaController = require('../controllers/abhaController');

// Get Dashboard Stats
router.get('/dashboard-stats', protect, authorize('Pharmacist'), async (req, res) => {
    try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        const prescriptionsToday = await Prescription.countDocuments({ 
            date: { $gte: today } 
        });
        
        const provider = await User.findById(req.user.id);
        const uniqueAbhaIds = await Prescription.distinct('abhaId');
        const allPatientIds = [...new Set([...uniqueAbhaIds, ...(provider.patients || [])])];
        
        res.json({
            prescriptionsToday,
            pendingOrders: 0, 
            totalCustomers: allPatientIds.length
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Register Patient via ABHA OTP (Pharmacist)
router.post('/patients/abha-register', protect, authorize('Pharmacist'), abhaController.registerPatientViaAbha);

// Get Pharmacist's Patients
router.get('/patients', protect, authorize('Pharmacist'), async (req, res) => {
    try {
        const provider = await User.findById(req.user.id);
        const uniqueAbhaIds = await Prescription.distinct('abhaId'); // For pharmacist, it might just be all prescriptions or just those they interacted with
        const allPatientIds = [...new Set([...uniqueAbhaIds, ...(provider.patients || [])])];
        
        const patients = await User.find({ abhaId: { $in: allPatientIds }, role: 'Patient' });
        res.json(patients);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get Pharmacist's Prescriptions
router.get('/prescriptions', protect, authorize('Pharmacist'), async (req, res) => {
    try {
        const prescriptions = await Prescription.find().sort({ date: -1 });
        res.json(prescriptions);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Update Prescription Pharmacist Notes
router.put('/prescriptions/:id/notes', protect, authorize('Pharmacist'), async (req, res) => {
    try {
        const { pharmacistNotes } = req.body;
        const prescription = await Prescription.findById(req.params.id);
        
        if (!prescription) return res.status(404).json({ message: 'Prescription not found' });
        
        if (pharmacistNotes !== undefined) prescription.pharmacistNotes = pharmacistNotes;
        
        await prescription.save();
        res.json(prescription);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Get Inventory
router.get('/inventory', protect, authorize('Pharmacist'), async (req, res) => {
    try {
        const inventory = await Inventory.find({ pharmacistId: req.user.id }).sort({ medicineName: 1 });
        res.json(inventory);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Add or Update Inventory Item
router.post('/inventory', protect, authorize('Pharmacist'), async (req, res) => {
    try {
        const { medicineName, quantity, price, expiryDate } = req.body;

        if (!medicineName || quantity === undefined || price === undefined) {
            return res.status(400).json({ message: 'Medicine Name, Quantity, and Price are required' });
        }

        // Try to find if this medicine is already in the pharmacist's inventory
        let item = await Inventory.findOne({ pharmacistId: req.user.id, medicineName });

        if (item) {
            // Update existing
            item.quantity += quantity; // Or just set it if we want absolute override. Let's do absolute override for now since they might be doing inventory count.
            // Wait, the plan was just to add stock or update. Let's just override quantity if it exists, or maybe add.
            // A realistic system would add. But an absolute set is safer for a simple app. We'll set absolute.
            item.quantity = quantity;
            item.price = price;
            if (expiryDate) item.expiryDate = expiryDate;
            await item.save();
        } else {
            // Create new
            item = await Inventory.create({
                pharmacistId: req.user.id,
                medicineName,
                quantity,
                price,
                expiryDate
            });
        }

        res.status(201).json(item);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

const Bill = require('../models/Bill');

// Generate Bill
router.post('/bills', protect, authorize('Pharmacist'), async (req, res) => {
    try {
        const { abhaId, patientName, prescriptionId, medicines, grandTotal } = req.body;

        if (!medicines || medicines.length === 0) {
            return res.status(400).json({ message: 'No medicines provided for billing' });
        }

        // Deduct inventory
        for (let item of medicines) {
            const inventoryItem = await Inventory.findOne({ 
                pharmacistId: req.user.id, 
                medicineName: item.medicineName 
            });

            if (inventoryItem) {
                inventoryItem.quantity -= item.quantity;
                if (inventoryItem.quantity < 0) inventoryItem.quantity = 0;
                await inventoryItem.save();
            }
        }

        const newBill = await Bill.create({
            pharmacistId: req.user.id,
            abhaId,
            patientName: patientName || 'Guest Patient',
            prescriptionId,
            medicines,
            grandTotal
        });

        res.status(201).json(newBill);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error while creating bill' });
    }
});

module.exports = router;
