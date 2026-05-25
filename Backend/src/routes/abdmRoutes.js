const express = require('express');
const router = express.Router();
const abdmService = require('../services/abdmService');

// Sandbox webhook callback for auth/on-init
router.post('/webhook/v0.5/users/auth/on-init', (req, res) => {
    console.log('[WEBHOOK] Received /auth/on-init:', JSON.stringify(req.body, null, 2));
    
    // ABDM Sandbox requires you to send a 202 Accepted immediately
    res.status(202).send();

    const { auth, error, resp } = req.body;
    
    if (resp && resp.requestId) {
        // Cache the result using the original requestId
        abdmService.cache.set(resp.requestId, {
            status: error ? 'ERROR' : 'SUCCESS',
            transactionId: auth?.transactionId,
            error: error
        });
    }
});

// Sandbox webhook callback for auth/on-confirm
router.post('/webhook/v0.5/users/auth/on-confirm', (req, res) => {
    console.log('[WEBHOOK] Received /auth/on-confirm:', JSON.stringify(req.body, null, 2));
    
    res.status(202).send();

    const { auth, error, resp } = req.body;
    
    if (resp && resp.requestId) {
        // Cache the result using the original requestId
        abdmService.cache.set(resp.requestId, {
            status: error ? 'ERROR' : 'SUCCESS',
            patient: auth?.patient,
            accessToken: auth?.accessToken,
            error: error
        });
    }
});

// General callback for HIP/HIU registration webhook 
// (The one we configured in the bridge setup script)
router.post('/webhook/hip', (req, res) => {
    console.log('[WEBHOOK] Received HIP callback:', JSON.stringify(req.body, null, 2));
    res.status(202).send();
});

router.post('/webhook/hiu', (req, res) => {
    console.log('[WEBHOOK] Received HIU callback:', JSON.stringify(req.body, null, 2));
    res.status(202).send();
});

module.exports = router;
