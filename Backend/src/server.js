const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Database Connection
mongoose.connect(process.env.MONGO_URI)
    .then(() => console.log('MongoDB Connected'))
    .catch(err => console.log(err));

// Serve static files from Frontend/public
const path = require('path');
app.use(express.static(path.join(__dirname, '../../Frontend/public')));

// Import Routes
const authRoutes = require('./routes/authRoutes');
const doctorRoutes = require('./routes/doctorRoutes');
const patientRoutes = require('./routes/patientRoutes');
const pharmacistRoutes = require('./routes/pharmacistRoutes');
const labTesterRoutes = require('./routes/labTesterRoutes');

app.use('/api/auth', authRoutes);
app.use('/api/v1/doctor', doctorRoutes);
app.use('/api/v1/patient', patientRoutes);
app.use('/api/v1/pharmacist', pharmacistRoutes);
app.use('/api/v1/lab_tester', labTesterRoutes);

// ABDM Webhook Routes
const abdmRoutes = require('./routes/abdmRoutes');
app.use('/api/abdm', abdmRoutes);
app.use('/v0.5', abdmRoutes);

// Mock ABDM Gateway (For Presentation)
const mockAbdmGateway = require('./routes/mockAbdmGateway');
app.use('/mock-gateway', mockAbdmGateway);

// Public Routes
const publicRoutes = require('./routes/publicRoutes');
app.use('/api/public', publicRoutes);

// Test Routes
const testRoutes = require('./routes/testRoutes');
app.use('/api/test', testRoutes);
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
