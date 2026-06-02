const mongoose = require('mongoose');

const prescriptionSchema = new mongoose.Schema({
    abhaId: {
        type: String,
        required: true,
        index: true,
    },
    doctorId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },
    doctorName: {
        type: String,
        required: true,
    },
    diagnosis: {
        type: String,
        required: true,
    },
    date: {
        type: Date,
        default: Date.now,
    },
    status: {
        type: String,
        enum: ['Active', 'Past'],
        default: 'Active'
    },
    doctorNotes: {
        type: String,
    },
    pharmacistNotes: {
        type: String,
    },
    medicines: [{
        name: { type: String, required: true },
        medicineId: { type: mongoose.Schema.Types.ObjectId, ref: 'Medicine' },
        frequency: { type: String }, // e.g., "1-0-1"
        duration: { type: String },  // e.g., "5 days"
    }],
    labTests: [{
        type: String
    }],
    digitalSignature: {
        type: String,
    }
}, { timestamps: true });

module.exports = mongoose.model('Prescription', prescriptionSchema);
