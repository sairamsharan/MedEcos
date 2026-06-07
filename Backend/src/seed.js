const mongoose = require('mongoose');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');

// Models
const User = require('./models/User');
const Prescription = require('./models/Prescription');
const Appointment = require('./models/Appointment');
const MockABDMUser = require('./models/MockABDMUser');
const Medicine = require('./models/Medicine');
const Inventory = require('./models/Inventory');
const LabTestOrder = require('./models/LabTestOrder');
const MedicineHistory = require('./models/MedicineHistory');
const Bill = require('./models/Bill');
const Otp = require('./models/Otp');

dotenv.config();

// Helper for digital signature
const generateKeys = () => crypto.generateKeyPairSync('rsa', {
    modulusLength: 2048,
    publicKeyEncoding: { type: 'spki', format: 'pem' },
    privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
});

const signPayload = (payload, privateKey) => {
    const sign = crypto.createSign('SHA256');
    sign.update(JSON.stringify(payload));
    sign.end();
    return sign.sign(privateKey, 'base64');
};

const seedDatabase = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('MongoDB Connected for Seeding...');

        // Clear all existing data
        await User.deleteMany({});
        await Medicine.deleteMany({});
        await Prescription.deleteMany({});
        await Appointment.deleteMany({});
        await MockABDMUser.deleteMany({});
        await Inventory.deleteMany({});
        await LabTestOrder.deleteMany({});
        await MedicineHistory.deleteMany({});
        await Bill.deleteMany({});
        await Otp.deleteMany({});
        console.log('Cleared existing data.');

        // ---------------------------------------------------------
        // 1. Mock ABDM Database
        // ---------------------------------------------------------
        const abdmUsers = await MockABDMUser.insertMany([
            { abhaId: '9999-8888-7777-6666', name: 'Abhinav Sharma', age: 34, gender: 'Male', mobileNumber: '9876543210' },
            { abhaId: '5555-4444-3333-2222', name: 'Kavya Reddy', age: 28, gender: 'Female', mobileNumber: '8765432109' },
            { abhaId: '1111-2222-3333-4444', name: 'Rohan Gupta', age: 45, gender: 'Male', mobileNumber: '7654321098' }
        ]);
        console.log('Seeded Mock ABDM Users.');

        const salt = await bcrypt.genSalt(10);
        const defaultPassword = await bcrypt.hash('password123', salt);

        // ---------------------------------------------------------
        // 2. Users (Doctors, Patient, Pharmacist, Pathologist) in Hyderabad (near 17.454389, 78.392028)
        // ---------------------------------------------------------
        
        // Doctor 1
        const doc1Keys = generateKeys();
        const doctor1 = await User.create({
            username: 'Dr. K. Rao',
            email: 'dr.rao@gmail.com',
            password: defaultPassword,
            role: 'Doctor',
            publicKey: doc1Keys.publicKey,
            privateKey: doc1Keys.privateKey,
            speciality: 'General Physician',
            address: 'AIG Hospitals, Gachibowli, Hyderabad',
            hospital: 'AIG Hospitals',
            imageInitials: 'KR',
            location: { lat: 17.4435, lng: 78.3653 }, // Gachibowli
            experienceYears: 15,
            consultationFee: 600,
            rating: 4.8,
            reviewCount: 312
        });

        // Doctor 2
        const doc2Keys = generateKeys();
        const doctor2 = await User.create({
            username: 'Dr. Ananya Reddy',
            email: 'dr.ananya@gmail.com',
            password: defaultPassword,
            role: 'Doctor',
            publicKey: doc2Keys.publicKey,
            privateKey: doc2Keys.privateKey,
            speciality: 'Cardiologist',
            address: 'Medicover Hospitals, HITEC City, Hyderabad',
            hospital: 'Medicover Hospitals',
            imageInitials: 'AR',
            location: { lat: 17.4475, lng: 78.3756 }, // HITEC City
            experienceYears: 10,
            consultationFee: 800,
            rating: 4.9,
            reviewCount: 150
        });

        // Pathologist (Lab)
        const pathologist = await User.create({
            username: 'Apollo Diagnostics - Madhapur',
            email: 'apollo.lab@gmail.com',
            password: defaultPassword,
            role: 'Pathologist',
            address: 'Madhapur Main Road, Hyderabad',
            location: { lat: 17.4560, lng: 78.3910 }, // Near requested coord
            labTestsProvided: ['Complete Blood Count (CBC)', 'Lipid Profile', 'Thyroid Profile (T3, T4, TSH)', 'HbA1c', 'Liver Function Test (LFT)'],
        });

        // Pharmacist
        const pharmacist = await User.create({
            username: 'MedPlus Pharmacy Madhapur',
            email: 'medplus.madhapur@gmail.com',
            password: defaultPassword,
            role: 'Pharmacist',
            address: 'Ayyappa Society, Madhapur, Hyderabad',
            location: { lat: 17.4530, lng: 78.3930 }, // Near requested coord
        });

        // Patient 1 (from MockABDM)
        const patient1 = await User.create({
            username: 'Abhinav Sharma',
            email: 'abhinav@gmail.com',
            password: defaultPassword,
            role: 'Patient',
            abhaId: '9999-8888-7777-6666',
            age: 34,
            gender: 'Male',
            address: 'Kavuri Hills, Madhapur, Hyderabad',
            location: { lat: 17.4399, lng: 78.3976 }
        });

        // Patient 2 (from MockABDM)
        const patient2 = await User.create({
            username: 'Kavya Reddy',
            email: 'kavya@gmail.com',
            password: defaultPassword,
            role: 'Patient',
            abhaId: '5555-4444-3333-2222',
            age: 28,
            gender: 'Female',
            address: 'Jubilee Hills, Hyderabad',
            location: { lat: 17.4325, lng: 78.4070 }
        });

        console.log('Seeded Users (Doctors, Pathologist, Pharmacist, Patients).');

        // ---------------------------------------------------------
        // 3. Appointments
        // ---------------------------------------------------------
        const today = new Date();
        const yesterday = new Date(today.getTime() - 86400000);
        const tomorrow = new Date(today.getTime() + 86400000);
        const nextWeek = new Date(today.getTime() + 7 * 86400000);

        await Appointment.insertMany([
            { doctorId: doctor1._id, abhaId: patient1.abhaId, patientName: patient1.username, date: yesterday, status: 'Completed' },
            { doctorId: doctor1._id, abhaId: patient2.abhaId, patientName: patient2.username, date: today, status: 'Confirmed' },
            { doctorId: doctor2._id, abhaId: patient1.abhaId, patientName: patient1.username, date: tomorrow, status: 'Pending' },
            { doctorId: doctor2._id, abhaId: patient2.abhaId, patientName: patient2.username, date: nextWeek, status: 'RescheduleRequested', rescheduleDate: new Date(nextWeek.getTime() + 3600000), rescheduleNotes: 'Doctor is in surgery, can we meet an hour later?' }
        ]);
        console.log('Seeded Appointments.');

        // ---------------------------------------------------------
        // 4. Medicines (Global List)
        // ---------------------------------------------------------
        const meds = await Medicine.insertMany([
            { name: 'Paracetamol 500mg', chemicalFormula: 'C8H9NO2', doctorOnly: false },
            { name: 'Amoxicillin 500mg', chemicalFormula: 'C16H19N3O5S', doctorOnly: true },
            { name: 'Atorvastatin 20mg', chemicalFormula: 'C33H35FN2O5', doctorOnly: true },
            { name: 'Metformin 500mg', chemicalFormula: 'C4H11N5', doctorOnly: true },
            { name: 'Vitamin C 1000mg', chemicalFormula: 'C6H8O6', doctorOnly: false },
            { name: 'Cetirizine 10mg', chemicalFormula: 'C21H25ClN2O3', doctorOnly: false },
            { name: 'Ibuprofen 400mg', chemicalFormula: 'C13H18O2', doctorOnly: false },
            { name: 'Azithromycin 500mg', chemicalFormula: 'C38H72N2O12', doctorOnly: true },
            { name: 'Omeprazole 20mg', chemicalFormula: 'C17H19N3O3S', doctorOnly: false },
            { name: 'Amlodipine 5mg', chemicalFormula: 'C20H25ClN2O5', doctorOnly: true }
        ]);
        console.log('Seeded Medicines.');

        // ---------------------------------------------------------
        // 5. Inventories (Pharmacist)
        // ---------------------------------------------------------
        const inventories = meds.map(med => ({
            pharmacistId: pharmacist._id,
            medicineName: med.name,
            quantity: Math.floor(Math.random() * 200) + 50,
            price: Math.floor(Math.random() * 500) + 50
        }));
        await Inventory.insertMany(inventories);
        console.log('Seeded Inventories.');

        // ---------------------------------------------------------
        // 6. Prescriptions (Digitally Signed)
        // ---------------------------------------------------------
        // Prescription 1: Abhinav (General)
        const p1Payload = {
            abhaId: patient1.abhaId,
            diagnosis: 'Viral Fever & Body Ache',
            medicines: [
                { name: 'Paracetamol 500mg', frequency: '1-0-0-1', duration: '5 days' },
                { name: 'Vitamin C 1000mg', frequency: '1-0-0-0', duration: '10 days' }
            ],
            labTests: ['Complete Blood Count (CBC)']
        };
        const rx1 = await Prescription.create({
            abhaId: patient1.abhaId,
            patientName: patient1.username,
            patientAge: patient1.age,
            patientGender: patient1.gender,
            doctorId: doctor1._id,
            doctorName: doctor1.username,
            diagnosis: p1Payload.diagnosis,
            medicines: p1Payload.medicines,
            labTests: p1Payload.labTests,
            digitalSignature: signPayload(p1Payload, doctor1.privateKey),
            date: yesterday
        });

        // Prescription 2: Kavya (Cardio)
        const p2Payload = {
            abhaId: patient2.abhaId,
            diagnosis: 'Hypertension & Hyperlipidemia',
            medicines: [
                { name: 'Atorvastatin 20mg', frequency: '0-0-0-1', duration: '30 days' },
                { name: 'Amlodipine 5mg', frequency: '1-0-0-0', duration: '30 days' }
            ],
            labTests: ['Lipid Profile']
        };
        const rx2 = await Prescription.create({
            abhaId: patient2.abhaId,
            patientName: patient2.username,
            patientAge: patient2.age,
            patientGender: patient2.gender,
            doctorId: doctor2._id,
            doctorName: doctor2.username,
            diagnosis: p2Payload.diagnosis,
            medicines: p2Payload.medicines,
            labTests: p2Payload.labTests,
            digitalSignature: signPayload(p2Payload, doctor2.privateKey),
            date: today
        });
        
        // Prescription 3: Abhinav (Infection)
        const p3Payload = {
            abhaId: patient1.abhaId,
            diagnosis: 'Respiratory Tract Infection',
            medicines: [
                { name: 'Amoxicillin 500mg', frequency: '1-1-0-1', duration: '7 days' },
                { name: 'Cetirizine 10mg', frequency: '0-0-0-1', duration: '5 days' }
            ],
            labTests: []
        };
        const rx3 = await Prescription.create({
            abhaId: patient1.abhaId,
            patientName: patient1.username,
            patientAge: patient1.age,
            patientGender: patient1.gender,
            doctorId: doctor1._id,
            doctorName: doctor1.username,
            diagnosis: p3Payload.diagnosis,
            medicines: p3Payload.medicines,
            labTests: p3Payload.labTests,
            digitalSignature: signPayload(p3Payload, doctor1.privateKey),
            date: new Date(today.getTime() - 5 * 86400000)
        });

        console.log('Seeded Prescriptions.');

        // ---------------------------------------------------------
        // 7. LabTestOrders
        // ---------------------------------------------------------
        // Order 1: Completed PDF Report (Mock base64)
        const samplePdfBase64 = "JVBERi0xLjQKJcOkw7zDtsOfCjIgMCBvYmoKPDwvTGVuZ3RoIDMgMCBSL0ZpbHRlci9GbGF0ZURlY29kZT4+CnN0cmVhbQp4nDPQM1Qo5ypUMFAwALJMLY2UjDUMlXw8nDyFDFRMDA0MTAyUgDwFc70UBQslE6B4sJOvkLmeQkBRaohfUDBQSC3KTE0sLknMKwaaZQzXAhTwyU9MyUksLgYaxgoA10AW1gplbmRzdHJlYW0KZW5kb2JqCgozIDAgb2JqCjg3CmVuZG9iagoKMSAwIG9iago8PC9UeXBlL1BhZ2UvTWVkaWFCb3hbMCAwIDU5NSA4NDJdL1BhcmVudCA0IDAgUi9SZXNvdXJjZXM8PC9Gb250PDwvRjEgNSAwIFI+Pj4+L0NvbnRlbnRzIDIgMCBSPj4KZW5kb2JqCgo0IDAgb2JqCjw8L1R5cGUvUGFnZXMvQ291bnQgMS9LaWRzWzEgMCBSXT4+CmVuZG9iagoKNSAwIG9iago8PC9UeXBlL0ZvbnQvU3VidHlwZS9UeXBlMS9CYXNlRm9udC9IZWx2ZXRpY2E+PgplbmRvYmoKCjYgMCBvYmoKPDwvVHlwZS9DYXRhbG9nL1BhZ2VzIDQgMCBSPj4KZW5kb2JqCgo3IDAgb2JqCjw8L1Byb2R1Y2VyKEdob3N0c2NyaXB0IDkuNTMpL0NyZWF0aW9uRGF0ZShEOjIwMjQwNjA3MDAwMDAwWik+PgplbmRvYmoKeHJlZgowIDgKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDAwMTU1IDAwMDAwIG4gCjAwMDAwMDAwMTUgMDAwMDAgbiAKMDAwMDAwMDEzNCAwMDAwMCBuIAowMDAwMDAwMjQ5IDAwMDAwIG4gCjAwMDAwMDAzMDYgMDAwMDAgbiAKMDAwMDAwMDM5NCAwMDAwMCBuIAowMDAwMDAwNDQ0IDAwMDAwIG4gCnRyYWlsZXIKPDwvU2l6ZSA4L1Jvb3QgNiAwIFIvSW5mbyA3IDAgUj4+CnN0YXJ0eHJlZgo1NDIKJSVFT0YK";
        
        await LabTestOrder.create({
            patientId: patient1._id,
            patientName: patient1.username,
            pathologistId: pathologist._id,
            testName: 'Complete Blood Count (CBC)',
            prescriptionId: rx1._id,
            status: 'Completed',
            dateCompleted: today,
            reportPdf: samplePdfBase64
        });

        // Order 2: In Progress
        await LabTestOrder.create({
            patientId: patient2._id,
            patientName: patient2.username,
            pathologistId: pathologist._id,
            testName: 'Lipid Profile',
            prescriptionId: rx2._id,
            status: 'In_Progress'
        });

        console.log('Seeded LabTestOrders.');

        // ---------------------------------------------------------
        // 8. MedicineHistory
        // ---------------------------------------------------------
        await MedicineHistory.insertMany([
            {
                abhaId: patient1.abhaId,
                patient: patient1._id,
                medicineId: meds[0]._id, // Paracetamol
                medicineName: 'Paracetamol 500mg',
                takenTime: yesterday,
                status: 'TAKEN'
            },
            {
                abhaId: patient1.abhaId,
                patient: patient1._id,
                medicineId: meds[4]._id, // Vitamin C
                medicineName: 'Vitamin C 1000mg',
                takenTime: yesterday,
                status: 'TAKEN'
            },
            {
                abhaId: patient2.abhaId,
                patient: patient2._id,
                medicineId: meds[2]._id, // Atorvastatin
                medicineName: 'Atorvastatin 20mg',
                takenTime: today,
                status: 'MISSED'
            }
        ]);
        console.log('Seeded MedicineHistories.');

        console.log('-------------------------------------------');
        console.log('SEEDING COMPLETED SUCCESSFULLY!');
        console.log('-------------------------------------------');
        console.log('Test Accounts (Password: password123)');
        console.log('- Doctor: dr.rao@gmail.com (AIG Hospitals)');
        console.log('- Doctor: dr.ananya@gmail.com (Medicover)');
        console.log('- Pathologist: apollo.lab@gmail.com');
        console.log('- Pharmacist: medplus.madhapur@gmail.com');
        console.log('- Patient: abhinav@gmail.com (ABHA: 9999-8888-7777-6666)');
        console.log('- Patient: kavya@gmail.com (ABHA: 5555-4444-3333-2222)');
        console.log('-------------------------------------------');

        process.exit();
    } catch (error) {
        console.error('Error during seeding:', error);
        process.exit(1);
    }
};

seedDatabase();
