const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    username: {
        type: String,
        required: false, // Optional for ABHA users initially
        unique: true,
        sparse: true // Allow nulls/missing to not conflict
    },
    email: {
        type: String,
        required: false,
        unique: true,
        sparse: true
    },
    password: {
        type: String,
        required: false,
    },
    age: {
        type: Number,
    },
    gender: {
        type: String,
        enum: ['Male', 'Female', 'Other'],
    },
    role: {
        type: String,
        enum: ['Doctor', 'Patient', 'Pharmacist', 'Lab_Tester'],
        default: 'Patient',
    },
    abhaId: {
        type: String,
        unique: true,
        sparse: true, // Only for patients
    },
    aadhaarNumber: {
        type: String,
        select: false, // Don't return by default
    },
    publicKey: {
        type: String, // Store PEM formatted key
    },
    privateKey: {
        type: String, // Store PEM formatted key
        select: false, // Ensure not returned in normal queries
    },
    // New Profile Fields
    address: {
        type: String,
    },
    location: {
        lat: { type: Number },
        lng: { type: Number },
    },
    routine: {
        morning: { type: String, default: '08:00 AM' },
        afternoon: { type: String, default: '01:00 PM' },
        evening: { type: String, default: '05:00 PM' },
        night: { type: String, default: '09:00 PM' }
    },

    // Doctor Specific Fields
    speciality: {
        type: String,
    },
    experienceYears: {
        type: Number,
    },
    consultationFee: {
        type: Number,
    },
    rating: {
        type: Number,
        default: 0,
    },
    reviewCount: {
        type: Number,
        default: 0,
    },
    hospital: {
        type: String,
    },
    imageInitials: {
        type: String,
    },
    // Track patients that a doctor/pharmacist has explicitly registered/interacted with
    patients: [{
        type: String
    }],
    labTestsProvided: [{
        type: String
    }]
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
