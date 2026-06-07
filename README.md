# MedEcos Unified Medical Platform

🚀 **Live App:** [https://medecos.netlify.app/](https://medecos.netlify.app/)

MedEcos is a comprehensive, modern Medical Ecosystem that seamlessly connects Patients, Doctors, and Pharmacists into a unified Flutter web application powered by a robust Node.js backend.

## Project Structure

This project has been heavily overhauled to integrate all roles into one cohesive application:

- **[Backend](./Backend/README.md)**: A Node.js/Express REST API utilizing MongoDB. It handles authentication, role-based access control (RBAC), and manages the secure flow of medical data (Prescriptions, Appointments, Patient Histories).
- **[Frontend](./Frontend/README.md)**: A single, unified Flutter Web application (`med_ecos_app`) that dynamically adapts its UI/UX and routing based on whether the logged-in user is a Patient, Doctor, or Pharmacist.

## Core Features

### For Patients
*   **Active Medicine Tracker**: View all currently prescribed medicines and mark them as "Taken".
*   **Doctor Appointments**: Search for verified doctors in the system and send appointment requests with detailed notes.
*   **Comprehensive Health Records**: Securely view past and active prescriptions, and maintain a profile tied to an ABHA ID.

### For Doctors
*   **Unified Patient Roster**: A "Patient Lookup" tab automatically tracks any patient the doctor interacts with or registers.
*   **ABHA Integration**: Instantly register new patients into the MedEcos system by querying their ABHA ID from the national database.
*   **Digital Prescriptions**: Issue prescriptions digitally. Prescriptions feature visual 4-dot frequency indicators and can be toggled between "Active" and "Past".
*   **Save as PDF**: Generate and download beautifully formatted PDF versions of prescriptions.

### For Pharmacists
*   **Global Patient Lookup**: Pharmacists can also instantly register patients via ABHA ID and track their customers.
*   **Prescription Fulfillment**: Pharmacists can view global prescriptions, verify them, and add their own "Pharmacist Notes" directly onto the prescription record.

## Getting Started

To launch the entire platform (Frontend + Backend) simultaneously:

```bash
# In the root directory, run the provided bash script:
./start_all.sh
```

This script will automatically:
1. Start the Node.js backend on Port 5000.
2. Seed the MongoDB database with realistic mock data.
3. Serve the compiled Flutter Web frontend on Port 3000.

You can then visit `http://localhost:3000` to interact with the app.

For more detailed information, please refer to the specific documentation for each component:
- [Backend Documentation](./Backend/README.md)
- [Frontend Documentation](./Frontend/README.md)
