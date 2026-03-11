const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/authMiddleware');

// Public Route
router.get('/public', (req, res) => {
    res.json({ message: 'Public route accessible to everyone' });
});

// Protected Route (Any Logged In User)
router.get('/protected', protect, (req, res) => {
    res.json({ message: `Protected route accessible to ${req.user.role}`, user: req.user });
});

// Doctor Only
router.get('/doctor', protect, authorize('Doctor'), (req, res) => {
    res.json({ message: 'Access granted to Doctor' });
});

// Patient Only
router.get('/patient', protect, authorize('Patient'), (req, res) => {
    res.json({ message: 'Access granted to Patient' });
});

// Pharmacist Only
router.get('/pharmacist', protect, authorize('Pharmacist'), (req, res) => {
    res.json({ message: 'Access granted to Pharmacist' });
});

// Pathologist Only
router.get('/pathologist', protect, authorize('Pathologist'), (req, res) => {
    res.json({ message: 'Access granted to Pathologist' });
});

module.exports = router;
