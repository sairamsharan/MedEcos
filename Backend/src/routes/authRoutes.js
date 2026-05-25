const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const User = require('../models/User');
const abdmService = require('../services/abdmService');

// Register
router.post('/register', async (req, res) => {
    try {
        const { username, email, password, role } = req.body;

        // Simple validation
        if (!username || !email || !password || !role) {
            return res.status(400).json({ message: 'Please enter all fields' });
        }

        // Validate Role
        const validRoles = ['Doctor', 'Patient', 'Pharmacist', 'Pathologist'];
        if (!validRoles.includes(role)) {
            return res.status(400).json({ message: 'Invalid role' });
        }

        // Check for existing user
        const userExists = await User.findOne({ email });
        if (userExists) {
            return res.status(400).json({ message: 'User already exists' });
        }

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // Generate RSA key pair if Role is Doctor
        let publicKey = undefined;
        let privateKey = undefined;

        if (role === 'Doctor') {
            const { publicKey: pubKey, privateKey: privKey } = crypto.generateKeyPairSync('rsa', {
                modulusLength: 2048,
                publicKeyEncoding: {
                    type: 'spki',
                    format: 'pem'
                },
                privateKeyEncoding: {
                    type: 'pkcs8',
                    format: 'pem'
                }
            });
            publicKey = pubKey;
            privateKey = privKey;
        }

        // Create user
        const user = await User.create({
            username,
            email,
            password: hashedPassword,
            role,
            publicKey, // Will be undefined if not Doctor
            privateKey // Will be undefined if not Doctor
        });

        if (user) {
            res.status(201).json({
                _id: user.id,
                username: user.username,
                email: user.email,
                role: user.role,
                token: generateToken(user._id, user.role),
            });
        } else {
            res.status(400).json({ message: 'Invalid user data' });
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Login
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        // Check for user email
        const user = await User.findOne({ email });

        if (user && (await bcrypt.compare(password, user.password))) {
            res.json({
                _id: user.id,
                username: user.username,
                email: user.email,
                role: user.role,
                token: generateToken(user._id, user.role),
            });
        } else {
            res.status(401).json({ message: 'Invalid credentials' });
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Generate OTP for ABHA via ABDM Gateway
router.post('/abha/generate-otp', async (req, res) => {
    try {
        const { abhaId } = req.body;
        if (!abhaId) {
            return res.status(400).json({ message: 'ABHA ID is required' });
        }

        const requestId = crypto.randomUUID();

        // 1. Initiate Auth with ABDM Gateway
        await abdmService.callGateway('/v0.5/users/auth/init', 'POST', {
            requestId: requestId,
            timestamp: new Date().toISOString(),
            query: {
                id: abhaId,
                purpose: "LINK",
                authMode: "MOBILE_OTP",
                requester: {
                    type: "HIP",
                    id: process.env.ABDM_CLIENT_ID + "_HIP"
                }
            }
        });

        // 2. Poll the cache for the webhook callback (wait max 10 seconds)
        let attempts = 0;
        let result = null;
        while (attempts < 10) {
            await new Promise(resolve => setTimeout(resolve, 1000));
            if (abdmService.cache.has(requestId)) {
                result = abdmService.cache.get(requestId);
                break;
            }
            attempts++;
        }

        if (!result || result.status === 'ERROR') {
            return res.status(500).json({ message: 'ABDM OTP Init Failed. Webhook did not receive callback or Gateway returned error.', error: result?.error });
        }

        res.json({
            transactionId: result.transactionId,
            message: 'OTP sent to linked mobile'
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: error.message || 'Server error' });
    }
});

// Verify OTP & Login/Register via ABDM Gateway
router.post('/abha/verify-otp', async (req, res) => {
    try {
        const { transactionId, otp, abhaId } = req.body;

        if (!transactionId || !otp || !abhaId) {
            return res.status(400).json({ message: 'All fields are required' });
        }

        const requestId = crypto.randomUUID();

        // 1. Confirm Auth with ABDM Gateway
        await abdmService.callGateway('/v0.5/users/auth/confirm', 'POST', {
            requestId: requestId,
            timestamp: new Date().toISOString(),
            transactionId: transactionId,
            credential: {
                authCode: otp
            }
        });

        // 2. Poll the cache for the webhook callback (wait max 10 seconds)
        let attempts = 0;
        let result = null;
        while (attempts < 10) {
            await new Promise(resolve => setTimeout(resolve, 1000));
            if (abdmService.cache.has(requestId)) {
                result = abdmService.cache.get(requestId);
                break;
            }
            attempts++;
        }

        if (!result || result.status === 'ERROR') {
            return res.status(400).json({ message: 'Invalid OTP or ABDM Error', error: result?.error });
        }

        // 3. User authenticated successfully, check if exists in MedEcos DB
        let user = await User.findOne({ abhaId });

        if (!user) {
            // Create new patient
            user = await User.create({
                abhaId,
                role: 'Patient',
                // We can use the demographic data returned by ABDM if needed
                // name: result.patient?.name
            });
        }

        res.json({
            _id: user.id,
            abhaId: user.abhaId,
            role: user.role,
            token: generateToken(user._id, user.role),
            abdmAccessToken: result.accessToken // Optionally pass ABDM token to frontend
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: error.message || 'Server error' });
    }
});

// Generate JWT
const generateToken = (id, role) => {
    return jwt.sign({ id, role }, process.env.JWT_SECRET, {
        expiresIn: '30d',
    });
};

module.exports = router;
