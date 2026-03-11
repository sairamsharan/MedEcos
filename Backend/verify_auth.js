const http = require('http');

const BASE_URL = 'http://localhost:3000/api';
const roles = ['Doctor', 'Patient', 'Pharmacist', 'Pathologist'];
const users = {}; // Store tokens

async function testAuth() {
    console.log('--- Starting Auth Verification ---');

    // 1. Register Users
    for (const role of roles) {
        const userData = {
            username: `${role.toLowerCase()}User`,
            email: `${role.toLowerCase()}@example.com`,
            password: 'password123',
            role: role
        };

        try {
            const res = await fetch(`${BASE_URL}/auth/register`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(userData)
            });

            if (res.status === 201) {
                const data = await res.json();
                console.log(`[PASS] Registered ${role}: ${data.email}`);
                users[role] = data.token;
            } else if (res.status === 400) {
                // Try login if already exists
                console.log(`[INFO] User ${role} already exists, logging in...`);
                const loginRes = await fetch(`${BASE_URL}/auth/login`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ email: userData.email, password: userData.password })
                });
                const loginData = await loginRes.json();
                if (loginRes.ok) {
                    console.log(`[PASS] Logged in ${role}`);
                    users[role] = loginData.token;
                } else {
                    console.error(`[FAIL] Could not login ${role}:`, loginData);
                }
            } else {
                console.error(`[FAIL] Register ${role}:`, await res.text());
            }
        } catch (err) {
            console.error(`[ERR] Register/Login ${role}:`, err.message);
        }
    }

    console.log('\n--- Verifying RBAC ---');

    // 2. Test Protected Routes
    for (const role of roles) { // User acting
        const token = users[role];
        if (!token) continue;

        console.log(`\nTesting as ${role}:`);

        // Try to access their own route
        const myRoute = role.toLowerCase();
        const myRes = await fetch(`${BASE_URL}/test/${myRoute}`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (myRes.status === 200) {
            console.log(`  [PASS] Access ${myRoute} route`);
        } else {
            console.log(`  [FAIL] Access ${myRoute} route: ${myRes.status}`);
        }

        // Try to access another role's route (e.g., Doctor tries Patient route)
        // Find a different role
        const otherRole = roles.find(r => r !== role);
        const otherRoute = otherRole.toLowerCase();

        const otherRes = await fetch(`${BASE_URL}/test/${otherRoute}`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });

        if (otherRes.status === 403) {
            console.log(`  [PASS] Blocked from ${otherRoute} route`);
        } else {
            console.log(`  [FAIL] Should be blocked from ${otherRoute} route but got: ${otherRes.status}`);
        }
    }
}

// Wait for server to start (manual delay or loop)
setTimeout(testAuth, 3000);
