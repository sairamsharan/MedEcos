const mongoose = require('mongoose');

const medicineSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        unique: true,
        trim: true,
    },
    chemicalFormula: {
        type: String,
        trim: true,
    }
}, { timestamps: true });

module.exports = mongoose.model('Medicine', medicineSchema);
