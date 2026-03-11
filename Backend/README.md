# MedEcos Backend

This is the backend service for the MedEcos platform. It provides a RESTful API built with Node.js, Express, and MongoDB.

## Tech Stack
- **Node.js**: JavaScript runtime
- **Express.js**: Web framework for APIs
- **MongoDB** (with Mongoose): NoSQL database for data persistence
- **JWT (JSON Web Tokens)**: For secure authentication
- **Bcrypt.js**: For password hashing

## Requirements
- Node.js (v18+ recommended)
- MongoDB running locally or a MongoDB Atlas connection string

## Setup & Installation

1. Navigate to the backend directory:
   ```bash
   cd Backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Setup Environment Variables:
   Create a `.env` file in the root of the `Backend` directory and define required variables (e.g., `MONGO_URI`, `JWT_SECRET`, `PORT`).

4. Start the development server:
   ```bash
   npm run dev
   ```

5. Start the production server:
   ```bash
   npm start
   ```

## API Documentation
For detailed API endpoints, request/response formats, please refer to:
- [Backend API Specifications](./backend_api_specs.md)
