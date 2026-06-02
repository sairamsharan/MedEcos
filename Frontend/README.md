# MedEcos Frontend

The Frontend of the MedEcos ecosystem is built as a **Single, Unified Flutter Web Application**. Rather than maintaining three separate codebases, the application dynamically adapts its User Interface and routing based on the logged-in user's role (Patient, Doctor, Pharmacist).

## Architecture & Features

The application is located in the `med_ecos_app` directory. It uses a scalable, feature-first folder structure (`lib/features/`) separating concerns by domain (auth, dashboard, prescription, appointments, patient_lookup, profile).

### Unified Role-Based Access
- **API Service Singleton:** A central `ApiService` manages all network requests and caches the JWT token and user role locally using `SharedPreferences`.
- **Dynamic Navigation:** The Sidebar and Main Content areas automatically render different tabs (e.g., "Patient Lookup" for Doctors/Pharmacists, "Appointments" for Patients/Doctors) based on the current role.

### Key Capabilities
- **PDF Generation:** Integrates the `pdf` and `printing` packages to generate and download beautifully formatted prescriptions.
- **Cross-Role Collaboration:** Doctors can issue prescriptions and add "Doctor Notes". Pharmacists can fulfill them and add "Pharmacist Notes", all visible instantly on the Patient's profile.
- **Live Search & Registration:** Doctors and Pharmacists can search the ABDM database by ABHA ID and instantly register a patient into the MedEcos system if they don't already exist.

## Getting Started

To run the Flutter frontend in development mode:

```bash
# Navigate to the main app directory
cd med_ecos_app

# Fetch dependencies
flutter pub get

# Run the app locally on a specific port (e.g., 3000)
flutter run -d web-server --web-port=3000
```

To build a production web bundle:
```bash
flutter build web
```

## Legacy Folders
*Note: The older `med_ecos_patient`, `med_ecos_doctor`, and `med_ecos_pharmacist` folders are deprecated and superseded entirely by `med_ecos_app`.*
