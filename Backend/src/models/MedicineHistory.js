const mongoose = require('mongoose');

const medicineHistorySchema = new mongoose.Schema({
    patient: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    abhaId: {
        type: String,
        required: true
    },
    medicineId: {
        type: String,
        required: true
    },
    medicineName: {
        type: String,
        required: true
    },
    takenTime: {
        type: Date,
        default: Date.now
    },
    status: {
        type: String,
        enum: ['TAKEN', 'MISSED', 'SKIPPED'],
        default: 'TAKEN'
    }
}, { timestamps: true });

module.exports = mongoose.model('MedicineHistory', medicineHistorySchema);
