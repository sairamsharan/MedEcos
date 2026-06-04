const mongoose = require('mongoose');

const inventorySchema = new mongoose.Schema({
    pharmacistId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },
    medicineName: {
        type: String,
        required: true,
        trim: true,
    },
    quantity: {
        type: Number,
        required: true,
        default: 0,
        min: 0,
    },
    price: {
        type: Number,
        required: true,
        min: 0,
    },
    expiryDate: {
        type: Date,
    }
}, { timestamps: true });

// Ensure a pharmacist doesn't have duplicate inventory entries for the same medicine name.
// Instead of creating a new document, they should update the quantity of the existing one.
inventorySchema.index({ pharmacistId: 1, medicineName: 1 }, { unique: true });

module.exports = mongoose.model('Inventory', inventorySchema);
