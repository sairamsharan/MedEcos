const abdmService = require('./src/services/abdmService');
require('dotenv').config();

async function testInit() {
    try {
        const token = await abdmService.getAccessToken();
        console.log("Token received.");
        const res = await abdmService.callGateway('/v0.5/users/auth/init', 'POST', {
            requestId: "12345678-1234-1234-1234-123456789012",
            timestamp: new Date().toISOString(),
            query: {
                id: "karan@sbx",
                purpose: "LINK",
                authMode: "MOBILE_OTP",
                requester: {
                    type: "HIP",
                    id: process.env.ABDM_CLIENT_ID + "_HIP"
                }
            }
        });
        console.log("Auth Init Response:", res);
    } catch(e) {
        console.error("Auth Init Error:", e);
    }
}
testInit();
