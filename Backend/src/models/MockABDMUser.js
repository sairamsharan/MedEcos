const mongoose = require('mongoose');

const mockABDMUserSchema = new mongoose.Schema({
    abhaId: {
        type: String,
        required: true,
        unique: true
    },
    name: {
        type: String,
        required: true
    },
    age: {
        type: Number,
        required: true
    },
    gender: {
        type: String,
        enum: ['Male', 'Female', 'Other'],
        required: true
    },
    mobileNumber: {
        type: String,
        required: true
    }
}, { timestamps: true });

module.exports = mongoose.model('MockABDMUser', mockABDMUserSchema);
