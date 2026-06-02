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

        // 1. Create Doctor 1
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
            privateKey,
            speciality: 'General Physician',
            address: 'Apollo Clinic, Andheri',
            hospital: 'Apollo Clinic, Andheri',
            imageInitials: 'JD',
            location: { lat: 19.1196, lng: 72.8468 },
            experienceYears: 12,
            consultationFee: 400,
            rating: 4.8,
            reviewCount: 312
        });

        // Create Doctor 2
        const doctor2 = await User.create({
            username: 'Dr. Rajesh Mehta',
            email: 'doctor2@medecos.com',
            password: defaultPassword,
            role: 'Doctor',
            speciality: 'Cardiologist',
            address: 'Kokilaben Hospital, Versova',
            hospital: 'Kokilaben Hospital, Versova',
            imageInitials: 'RM',
            location: { lat: 19.1313, lng: 72.8197 },
            experienceYears: 20,
            consultationFee: 900,
            rating: 4.9,
            reviewCount: 518
        });

        // Create Doctor 3
        const doctor3 = await User.create({
            username: 'Dr. Sneha Patil',
            email: 'doctor3@medecos.com',
            password: defaultPassword,
            role: 'Doctor',
            speciality: 'Pediatrician',
            address: 'Rainbow Children\'s Clinic',
            hospital: 'Rainbow Children\'s Clinic',
            imageInitials: 'SP',
            location: { lat: 19.1110, lng: 72.8578 },
            experienceYears: 10,
            consultationFee: 500,
            rating: 4.9,
            reviewCount: 421
        });

        // 2. Create Patient
        const patient = await User.create({
            username: 'Jane Smith',
            email: 'patient@medecos.com',
            password: defaultPassword,
            role: 'Patient',
            abhaId: 'jane@abdm',
            address: '123 Link Road, Andheri West',
            location: { lat: 19.1234, lng: 72.8456 }
        });

        // 3. Create Pharmacist
        const pharmacist = await User.create({
            username: 'Pharma Care',
            email: 'pharmacist@medecos.com',
            password: defaultPassword,
            role: 'Pharmacist',
            address: 'Sion Circle, Mumbai',
            location: { lat: 19.0430, lng: 72.8627 }
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
        await Appointment.create({
            doctorId: doctor._id,
            abhaId: patient.abhaId,
            patientName: patient.username,
            date: new Date(Date.now() + 172800000), // In 2 days
            status: 'RescheduleRequested',
            rescheduleDate: new Date(Date.now() + 180000000),
            rescheduleNotes: 'Doctor is busy during requested time, how about later?'
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
            chemicalFormula: 'C8H9NO2',
            doctorOnly: false
        });
        await Medicine.create({
            name: 'Vitamin C 200mg',
            chemicalFormula: 'C6H8O6',
            doctorOnly: false
        });
        await Medicine.create({
            name: 'Amoxicillin 500mg',
            chemicalFormula: 'C16H19N3O5S',
            doctorOnly: true
        });
        await Medicine.create({
            name: 'Aspirin 75mg',
            chemicalFormula: 'C9H8O4',
            doctorOnly: true
        });
        await Medicine.create({
            name: 'Cetirizine 10mg',
            chemicalFormula: 'C21H25ClN2O3',
            doctorOnly: false
        });

        console.log('Seeding Completed Successfully!');
        process.exit();
    } catch (error) {
        console.error('Error during seeding:', error);
        process.exit(1);
    }
};

seedDatabase();
