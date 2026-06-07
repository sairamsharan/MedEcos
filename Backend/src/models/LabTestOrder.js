const mongoose = require('mongoose');

const labTestOrderSchema = new mongoose.Schema({
    patientId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    patientName: {
        type: String,
        required: true
    },
    pathologistId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    testName: {
        type: String,
        required: true
    },
    prescriptionId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Prescription'
    },
    status: {
        type: String,
        enum: ['Pending', 'In_Progress', 'Completed'],
        default: 'Pending'
    },
    dateRequested: {
        type: Date,
        default: Date.now
    },
    dateCompleted: {
        type: Date
    },
    notes: {
        type: String
    },
    reportPdf: {
        type: String // Base64 encoded PDF
    }
}, { timestamps: true });

module.exports = mongoose.model('LabTestOrder', labTestOrderSchema);
