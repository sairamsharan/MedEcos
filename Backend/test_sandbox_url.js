
async function testUrl(baseUrl) {
    console.log("Testing:", baseUrl);
    try {
        const response = await fetch(`${baseUrl}/v0.5/sessions`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'accept': 'application/json'
            },
            body: JSON.stringify({
                clientId: process.env.ABDM_CLIENT_ID,
                clientSecret: process.env.ABDM_CLIENT_SECRET
            })
        });
        const data = await response.json();
        console.log(baseUrl, "Response:", response.status, data);
        if(data.accessToken) {
            // try init
            const res2 = await fetch(`${baseUrl}/v0.5/users/auth/init`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${data.accessToken}`,
                    'Content-Type': 'application/json',
                    'X-CM-ID': 'sbx'
                },
                body: JSON.stringify({
                    requestId: "12345678-1234-1234-1234-123456789012",
                    timestamp: new Date().toISOString(),
                    query: { id: "karan@sbx", purpose: "LINK", authMode: "MOBILE_OTP", requester: { type: "HIP", id: "SBXID_018454_HIP" } }
                })
            });
            const text2 = await res2.text();
            console.log(baseUrl, "Init Response:", res2.status, text2);
        }
    } catch(e) {
        console.error(e.message);
    }
}

require('dotenv').config();
(async () => {
    await testUrl('https://sandbox.abdm.gov.in/gateway');
    await testUrl('https://dev.ndhm.gov.in/gateway');
})();
