
async function testV3() {
    try {
        const response = await fetch('https://dev.abdm.gov.in/api/hiecm/gateway/v3/sessions', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                clientId: process.env.ABDM_CLIENT_ID,
                clientSecret: process.env.ABDM_CLIENT_SECRET,
                grantType: "client_credentials"
            })
        });
        const data = await response.json();
        console.log("V3 Token Response:", data);
        if (data.accessToken) {
            // try bridges
            const res2 = await fetch('https://dev.abdm.gov.in/gateway/v1/bridges', {
                method: 'PATCH',
                headers: {
                    'Authorization': `Bearer ${data.accessToken}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ url: "https://abcdef123.com" })
            });
            console.log("Bridges response:", res2.status, await res2.text());
        }
    } catch(e) { console.error(e.message); }
}

require('dotenv').config();
testV3();
