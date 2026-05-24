const dotenv = require('dotenv');
dotenv.config();

// Use the local mock gateway for the presentation
const BASE_URL = `http://localhost:${process.env.PORT || 3000}/mock-gateway`;

class ABDMService {
    constructor() {
        this.token = null;
        this.tokenExpiresAt = null;
        this.cache = new Map(); // Simple in-memory cache for callbacks
    }

    async getAccessToken() {
        // Return existing token if valid
        if (this.token && this.tokenExpiresAt > Date.now()) {
            return this.token;
        }

        const clientId = process.env.ABDM_CLIENT_ID;
        const clientSecret = process.env.ABDM_CLIENT_SECRET;

        if (!clientId || !clientSecret) {
            throw new Error('ABDM credentials missing from environment variables');
        }

        try {
            const response = await fetch(`${BASE_URL}/v0.5/sessions`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'accept': 'application/json'
                },
                body: JSON.stringify({
                    clientId: clientId,
                    clientSecret: clientSecret
                })
            });

            const data = await response.json();

            if (!response.ok) {
                console.error("Gateway Auth Error:", data);
                throw new Error(data.error?.message || 'Failed to authenticate with ABDM gateway');
            }

            this.token = data.accessToken;
            // accessToken expires in some seconds, usually 3600
            const expiresIn = data.expiresIn || 3600;
            this.tokenExpiresAt = Date.now() + (expiresIn * 1000) - 60000; // 1 min buffer

            return this.token;
        } catch (error) {
            console.error('Error fetching ABDM access token:', error);
            throw error;
        }
    }

    async callGateway(endpoint, method, payload = null) {
        const token = await this.getAccessToken();
        
        const options = {
            method: method,
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json',
                'accept': '*/*',
                'X-CM-ID': 'sbx' // Common for sandbox requests
            }
        };

        if (payload) {
            options.body = JSON.stringify(payload);
        }

        const response = await fetch(`${BASE_URL}${endpoint}`, options);
        
        // Some APIs just return 202 Accepted with no body
        if (response.status === 202) {
            return { success: true };
        }

        const text = await response.text();
        if (!response.ok) {
            console.error(`Gateway Error [${endpoint}]:`, text);
            throw new Error(`ABDM API Error: ${text}`);
        }

        return text ? JSON.parse(text) : { success: true };
    }

    // Bridge setup functions
    async updateBridgeUrl(url) {
        return this.callGateway('/v1/bridges', 'PATCH', { url });
    }

    async addServices(services) {
        return this.callGateway('/v1/bridges/addUpdateServices', 'POST', services);
    }

    async getServices() {
        return this.callGateway('/v1/bridges/getServices', 'GET');
    }
}

module.exports = new ABDMService();
