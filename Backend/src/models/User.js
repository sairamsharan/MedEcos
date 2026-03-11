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
        enum: ['Doctor', 'Patient', 'Pharmacist', 'Pathologist'],
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
    }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
