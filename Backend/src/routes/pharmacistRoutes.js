const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/authMiddleware');
const Prescription = require('../models/Prescription');

// Get Dashboard Stats
router.get('/dashboard-stats', protect, authorize('Pharmacist'), async (req, res) => {
    try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        const prescriptionsToday = await Prescription.countDocuments({ 
            date: { $gte: today } 
        });
        
        const uniqueCustomers = (await Prescription.distinct('abhaId')).length;

        res.json({
            prescriptionsToday,
            pendingOrders: 5, // Mocked 
            totalCustomers: uniqueCustomers
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

module.exports = router;
