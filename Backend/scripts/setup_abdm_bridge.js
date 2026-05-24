const abdmService = require('../src/services/abdmService');
require('dotenv').config();

async function setupBridge() {
    console.log('--- Starting ABDM Bridge Setup ---');

    try {
        // Step 1: Authenticate
        console.log('1. Authenticating with ABDM Gateway...');
        const token = await abdmService.getAccessToken();
        console.log('   [SUCCESS] Received Access Token\n');

        // Step 2: Update Bridge URL
        const webhookUrl = process.env.ABDM_WEBHOOK_URL;
        if (!webhookUrl || !webhookUrl.startsWith('https')) {
            throw new Error('ABDM_WEBHOOK_URL must be defined and use HTTPS.');
        }

        console.log(`2. Updating Bridge URL to: ${webhookUrl} ...`);
        await abdmService.updateBridgeUrl(webhookUrl);
        console.log('   [SUCCESS] Bridge URL updated successfully.\n');

        // Step 3: Add Services (HIP/HIU)
        console.log('3. Adding HIP and HIU services to the bridge...');
        const services = [
            {
                id: process.env.ABDM_CLIENT_ID + "_HIP",
                name: "MedEcos HIP",
                type: "HIP",
                active: true,
                alias: ["medecos-hip"],
                endpoints: [
                    {
                        address: `${webhookUrl}/api/abdm/webhook/hip`,
                        connectionType: "https",
                        use: "registration"
                    }
                ]
            },
            {
                id: process.env.ABDM_CLIENT_ID + "_HIU",
                name: "MedEcos HIU",
                type: "HIU",
                active: true,
                alias: ["medecos-hiu"],
                endpoints: [
                    {
                        address: `${webhookUrl}/api/abdm/webhook/hiu`,
                        connectionType: "https",
                        use: "registration"
                    }
                ]
            }
        ];

        await abdmService.addServices(services);
        console.log('   [SUCCESS] Services added successfully.\n');

        // Step 4: Verify Services
        console.log('4. Fetching Registered Services to verify...');
        const registeredServices = await abdmService.getServices();
        console.log('   [SUCCESS] Bridge setup verified!');
        console.log('Registered Services:', JSON.stringify(registeredServices, null, 2));

    } catch (error) {
        console.error('\n[ERROR] Bridge setup failed:', error.message);
    }
}

setupBridge();
