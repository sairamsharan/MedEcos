// Native fetch is available in Node 18+

const BASE_URL = 'http://localhost:3000/api'; const ABHA_ID = "9999-8888-7777-6666";

async function runTest() {
    console.log('--- Starting ABHA Flow Verification ---');

    let doctorToken = '';
    let patientToken = '';

    // 1. Register & Login Doctor
    try {
        console.log('\n[1] Doctor Login/Register...');
        let res = await fetch(`${BASE_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: 'dr_test@example.com', password: 'password123' })
        });

        if (res.status === 401) {
            // Register if not exists
            console.log('    Doctor not found, registering...');
            res = await fetch(`${BASE_URL}/auth/register`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username: 'DrTest', email: 'dr_test@example.com', password: 'password123', role: 'Doctor' })
            });
        }

        const data = await res.json();
        if (data.token) {
            doctorToken = data.token;
            console.log('    [PASS] Doctor Logged In');
        } else {
            throw new Error('Doctor login failed: ' + JSON.stringify(data));
        }

    } catch (err) {
        console.error('    [FAIL]', err.message);
        return;
    }

    // 2. Doctor creates Prescription
    try {
        console.log('\n[2] Creating Prescription for ABHA:', ABHA_ID);
        const res = await fetch(`${BASE_URL}/v1/doctor/prescriptions`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${doctorToken}`
            },
            body: JSON.stringify({
                abhaId: ABHA_ID,
                diagnosis: 'Test Diagnosis',
                medicines: [{ name: 'TestMeds', frequency: '1-0-1', duration: '3 days' }],
                labTests: ['Blood Test']
            })
        });

        if (res.status === 201) {
            console.log('    [PASS] Prescription Created');
        } else {
            const errData = await res.json();
            throw new Error('Prescription creation failed: ' + JSON.stringify(errData));
        }
    } catch (err) {
        console.error('    [FAIL]', err.message);
    }

    // 3. Patient Login (ABHA Flow)
    try {
        console.log('\n[3] Patient Login (Mock OTP)...');
        // Generate OTP (Mock)
        await fetch(`${BASE_URL}/auth/abha/generate-otp`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ abhaId: ABHA_ID })
        });

        // Verify OTP
        const res = await fetch(`${BASE_URL}/auth/abha/verify-otp`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                transactionId: 'txn-mock',
                otp: '123456',
                abhaId: ABHA_ID
            })
        });

        const data = await res.json();
        if (data.token) {
            patientToken = data.token;
            console.log('    [PASS] Patient Logged In (Token received)');
        } else {
            throw new Error('Patient login failed: ' + JSON.stringify(data));
        }

    } catch (err) {
        console.error('    [FAIL]', err.message);
        return;
    }

    // 4. Patient Checks History
    try {
        console.log('\n[4] Patient fetching Medical History...');
        const res = await fetch(`${BASE_URL}/v1/patient/prescriptions`, {
            headers: { 'Authorization': `Bearer ${patientToken}` }
        });

        const data = await res.json();
        if (res.ok && data.records && data.records.length > 0) {
            console.log('    [PASS] Medical History Retrieved');
            console.log(`    Found ${data.records.length} records.`);
            console.log('    First Record Diagnosis:', data.records[0].diagnosis);
        } else {
            console.log('    [FAIL] No history found or error:', data);
        }

    } catch (err) {
        console.error('    [FAIL]', err.message);
    }
}

runTest();
