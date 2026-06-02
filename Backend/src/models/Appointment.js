const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema({
    doctorId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    abhaId: {
        type: String,
        required: true
    },
    patientName: {
        type: String,
        required: true
    },
    date: {
        type: Date,
        required: true
    },
    status: {
        type: String,
        enum: ['Pending', 'Confirmed', 'Completed', 'Cancelled', 'RescheduleRequested'],
        default: 'Pending'
    },
    notes: {
        type: String
    },
    rescheduleDate: {
        type: Date
    },
    rescheduleNotes: {
        type: String
    }
}, { timestamps: true });

module.exports = mongoose.model('Appointment', appointmentSchema);
