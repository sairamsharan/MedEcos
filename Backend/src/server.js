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

// Routes (Placeholder)
app.get('/', (req, res) => {
    res.send('API is running...');
});

// Import Routes
const authRoutes = require('./routes/authRoutes');
app.use('/api/auth', authRoutes);

// Routes
const doctorRoutes = require('./routes/doctorRoutes');
const patientRoutes = require('./routes/patientRoutes');

app.use('/api/v1/doctor', doctorRoutes);
app.use('/api/v1/patient', patientRoutes);

// Public Routes
const publicRoutes = require('./routes/publicRoutes');
app.use('/api/public', publicRoutes);

// Test Routes
const testRoutes = require('./routes/testRoutes');
app.use('/api/test', testRoutes);
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
