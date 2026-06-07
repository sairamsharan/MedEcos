const mongoose = require('mongoose');

const billSchema = new mongoose.Schema({
    pharmacistId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    abhaId: {
        type: String, // Optional, can be empty for walk-in patients
    },
    patientName: {
        type: String,
        required: true,
        default: 'Guest Patient'
    },
    prescriptionId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Prescription', // Optional, if linked to a prescription
    },
    medicines: [{
        medicineName: {
            type: String,
            required: true
        },
        quantity: {
            type: Number,
            required: true
        },
        pricePerUnit: {
            type: Number,
            required: true
        },
        total: {
            type: Number,
            required: true
        }
    }],
    grandTotal: {
        type: Number,
        required: true
    },
    date: {
        type: Date,
        default: Date.now
    }
}, { timestamps: true });

module.exports = mongoose.model('Bill', billSchema);
