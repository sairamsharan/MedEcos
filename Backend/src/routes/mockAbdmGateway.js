const express = require('express');
const crypto = require('crypto');
const router = express.Router();

// This mocks the actual ABDM Gateway for your presentation
// so you don't depend on their broken servers!

// Mock Session
router.post('/v0.5/sessions', (req, res) => {
    res.json({
        accessToken: "mock-abdm-access-token-for-presentation",
        expiresIn: 3600,
        tokenType: "Bearer"
    });
});

// Mock Auth Init (Generate OTP)
router.post('/v0.5/users/auth/init', (req, res) => {
    const { requestId, query } = req.body;
    
    // Respond immediately with 202 Accepted (like real ABDM)
    res.status(202).send();

    // Simulate ABDM taking 1.5 seconds to process, then calling your webhook
    setTimeout(() => {
        const webhookPayload = {
            requestId: crypto.randomUUID(),
            timestamp: new Date().toISOString(),
            auth: {
                transactionId: "txn-mock-" + Date.now(),
                mode: "MOBILE_OTP"
            },
            resp: {
                requestId: requestId // Matches original request
            }
        };

        // Call your own webhook locally!
        const webhookUrl = process.env.ABDM_WEBHOOK_URL || `http://localhost:${process.env.PORT || 3000}`;
        fetch(`${webhookUrl}/api/abdm/webhook/v0.5/users/auth/on-init`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(webhookPayload)
        }).catch(err => console.error("Mock Webhook Error:", err));

    }, 1500);
});

// Mock Auth Confirm (Verify OTP)
router.post('/v0.5/users/auth/confirm', (req, res) => {
    const { requestId, transactionId, credential } = req.body;
    
    res.status(202).send();

    setTimeout(() => {
        // If OTP is 123456, succeed. Otherwise fail.
        const isSuccess = credential?.authCode === '123456';
        
        const webhookPayload = {
            requestId: crypto.randomUUID(),
            timestamp: new Date().toISOString(),
            auth: isSuccess ? {
                accessToken: "mock-patient-token-12345",
                patient: {
                    id: "karan@sbx",
                    name: "Karan Agarwal",
                    gender: "M",
                    yearOfBirth: 2002
                }
            } : null,
            error: isSuccess ? null : {
                code: 1000,
                message: "Invalid OTP"
            },
            resp: {
                requestId: requestId
            }
        };

        const webhookUrl = process.env.ABDM_WEBHOOK_URL || `http://localhost:${process.env.PORT || 3000}`;
        fetch(`${webhookUrl}/api/abdm/webhook/v0.5/users/auth/on-confirm`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(webhookPayload)
        }).catch(err => console.error("Mock Webhook Error:", err));

    }, 1500);
});

// Mock Bridge Setup
router.patch('/v1/bridges', (req, res) => res.status(202).send());
router.post('/v1/bridges/addUpdateServices', (req, res) => res.status(202).send());
router.get('/v1/bridges/getServices', (req, res) => res.json([{ id: "mock_hip", active: true }]));

module.exports = router;
