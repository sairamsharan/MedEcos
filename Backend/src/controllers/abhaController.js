const User = require('../models/User');
const Otp = require('../models/Otp');
const MockABDMUser = require('../models/MockABDMUser');

exports.registerPatientViaAbha = async (req, res) => {
    try {
        const { transactionId, otp, abhaId } = req.body;

        if (!transactionId || !otp || !abhaId) {
            return res.status(400).json({ message: 'All fields are required' });
        }

        // Verify OTP
        let otpDoc = null;
        if (transactionId === 'txn-mock') {
            if (otp !== '123456') {
                return res.status(400).json({ message: 'Invalid OTP' });
            }
        } else {
            otpDoc = await Otp.findOne({ transactionId, abhaId });
            if (!otpDoc || otpDoc.otp !== otp) {
                return res.status(400).json({ message: 'Invalid OTP or transaction expired' });
            }
        }

        // Check if user exists
        let user = await User.findOne({ abhaId });

        if (!user) {
            const abdmData = await MockABDMUser.findOne({ abhaId });
            
            user = await User.create({
                abhaId,
                role: 'Patient',
                username: abdmData ? abdmData.name : `patient_${abhaId.replace(/-/g, '')}`,
                age: abdmData ? abdmData.age : undefined,
                gender: abdmData ? abdmData.gender : undefined,
            });
        }

        if (otpDoc) {
            await Otp.deleteOne({ _id: otpDoc._id });
        }

        // Track this patient in the provider's document
        const provider = await User.findById(req.user.id);
        if (provider && !provider.patients.includes(abhaId)) {
            provider.patients.push(abhaId);
            await provider.save();
        }

        // Return the patient data
        res.json(user);

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: error.message || 'Server error' });
    }
};
