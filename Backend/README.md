# MedEcos Backend

This is the centralized backend service for the MedEcos platform. It provides a RESTful API built with Node.js, Express, and MongoDB, supporting the unified Flutter Web frontend.

## Tech Stack
- **Node.js**: JavaScript runtime
- **Express.js**: Web framework for modular APIs
- **MongoDB** (with Mongoose): NoSQL database for data persistence
- **JWT (JSON Web Tokens)**: Secure, stateless authentication
- **Bcrypt.js**: Secure password hashing

## Architecture & Data Flow
The backend separates its routes based on the three primary roles:
- `authRoutes.js`: Handles global login, profile fetching, and profile updates.
- `patientRoutes.js`: Exposes endpoints for patients to view their medical history, book appointments, and track active medicines.
- `doctorRoutes.js`: Handles patient lookup, digital prescription signing (using RSA cryptography), and appointment management.
- `pharmacistRoutes.js`: Handles global prescription fetching, patient tracking, and appending pharmacist usage notes to prescriptions.

### ABHA Integration
The backend mocks an integration with the Ayushman Bharat Digital Mission (ABDM). Doctors and Pharmacists can hit the `/patients/abha-register` endpoint with a valid ABHA ID. The backend will instantly check the `MockABDMUser` database and create a new unified `User` record in MedEcos, automatically establishing the relationship in the provider's `patients` array.

## Setup & Installation

1. Navigate to the backend directory:
   ```bash
   cd Backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Configure Environment Variables:
   Ensure you have a `.env` file in the root of the `Backend` directory containing required variables (e.g., `MONGO_URI`, `JWT_SECRET`, `PORT`).

4. Seed the Database:
   To completely clear the local database and populate it with realistic mock data (including the `1111-2222-3333-4444` sample patient):
   ```bash
   node src/seed.js
   ```

5. Start the development server (uses `nodemon` for hot-reloading):
   ```bash
   npm run dev
   ```

## API Documentation
For detailed API endpoints, request/response formats, please refer to the shared spec file located in the Frontend folder:
- [Backend API Specifications](../Frontend/backend_api_specs.md)
