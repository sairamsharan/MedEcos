const mongoose = require('mongoose');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const User = require('./models/User');
const Prescription = require('./models/Prescription');
const Appointment = require('./models/Appointment');
const MockABDMUser = require('./models/MockABDMUser');
const Medicine = require('./models/Medicine');

dotenv.config();

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
        console.log('Cleared existing data.');

        // Seed Mock ABDM Database
        await MockABDMUser.insertMany([
            { abhaId: '1111-2222-3333-4444', name: 'Rahul Sharma', age: 45, gender: 'Male', mobileNumber: '9876543210' },
            { abhaId: '9999-8888-7777-6666', name: 'Priya Singh', age: 32, gender: 'Female', mobileNumber: '8765432109' },
            { abhaId: '5555-4444-3333-2222', name: 'Ananya Gupta', age: 28, gender: 'Female', mobileNumber: '7654321098' },
            { abhaId: '1234-5678-9012-3456', name: 'Amit Patel', age: 50, gender: 'Male', mobileNumber: '6543210987' }
        ]);
        console.log('Seeded Mock ABDM Users.');

        const salt = await bcrypt.genSalt(10);
        const defaultPassword = await bcrypt.hash('password123', salt);

        // 1. Create Doctor
        const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
            modulusLength: 2048,
            publicKeyEncoding: { type: 'spki', format: 'pem' },
            privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
        });
        const doctor = await User.create({
            username: 'Dr. John Doe',
            email: 'doctor@medecos.com',
            password: defaultPassword,
            role: 'Doctor',
            publicKey,
            privateKey
        });

        // 2. Create Patient
        const patient = await User.create({
            username: 'Jane Smith',
            email: 'patient@medecos.com',
            password: defaultPassword,
            role: 'Patient',
            abhaId: 'jane@abdm'
        });

        // 3. Create Pharmacist
        const pharmacist = await User.create({
            username: 'Pharma Care',
            email: 'pharmacist@medecos.com',
            password: defaultPassword,
            role: 'Pharmacist'
        });

        // 4. Create Appointments
        await Appointment.create({
            doctorId: doctor._id,
            abhaId: patient.abhaId,
            patientName: patient.username,
            date: new Date(), // Today
            status: 'Confirmed'
        });
        await Appointment.create({
            doctorId: doctor._id,
            abhaId: patient.abhaId,
            patientName: patient.username,
            date: new Date(Date.now() - 86400000), // Yesterday
            status: 'Completed'
        });
        await Appointment.create({
            doctorId: doctor._id,
            abhaId: 'random@abdm',
            patientName: 'Random User',
            date: new Date(Date.now() + 86400000), // Tomorrow
            status: 'Pending'
        });

        // 5. Create Prescriptions
        const payload = JSON.stringify({
            abhaId: patient.abhaId,
            diagnosis: 'Viral Fever',
            medicines: [
                { name: 'Paracetamol 500mg', frequency: '1-0-1', duration: '5 days' }, 
                { name: 'Vitamin C', frequency: '1-0-0', duration: '10 days' }
            ],
            labTests: []
        });
        const sign = crypto.createSign('SHA256');
        sign.update(payload);
        sign.end();
        const digitalSignature = sign.sign(doctor.privateKey, 'base64');

        await Prescription.create({
            abhaId: patient.abhaId,
            doctorId: doctor._id,
            doctorName: doctor.username,
            diagnosis: 'Viral Fever',
            medicines: [
                { name: 'Paracetamol 500mg', frequency: '1-0-1', duration: '5 days' }, 
                { name: 'Vitamin C', frequency: '1-0-0', duration: '10 days' }
            ],
            digitalSignature
        });

        // 6. Create Medicines (Inventory)
        await Medicine.create({
            name: 'Paracetamol 500mg',
            dosage: '500mg',
            frequency: 3,
            timings: [],
            stock: 150
        });
        await Medicine.create({
            name: 'Vitamin C',
            dosage: '200mg',
            frequency: 1,
            timings: [],
            stock: 300
        });

        console.log('Seeding Completed Successfully!');
        process.exit();
    } catch (error) {
        console.error('Error during seeding:', error);
        process.exit(1);
    }
};

seedDatabase();
