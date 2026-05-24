# Backend API & Data Structure Specification (ABHA Enabled)

## 1. Authentication (ABHA & Roles)

### Doctors / Pharmacists / Pathologists
*   **Standard Login**
    *   **Endpoint:** `POST /auth/login`
    *   **Body:** `email`, `password`
    *   **Response:** `token`, `user`

### Patients (ABHA Flow)
*   **Generate OTP (Mock)**
    *   **Endpoint:** `POST /auth/abha/generate-otp`
    *   **Body:** `abhaId` (e.g., "1234-5678-9012-3456")
    *   **Response:** `transactionId`, `message: "OTP sent to linked mobile"`

*   **Verify OTP & Login**
    *   **Endpoint:** `POST /auth/abha/verify-otp`
    *   **Body:** `transactionId`, `otp`, `abhaId`
    *   **Response:** `token`, `user` (creates user if first time)

---

## 2. Doctor App APIs

### Base URL: `/api/v1/doctor`

#### **Patients (by ABHA)**
*   **Search Patient**
    *   **Endpoint:** `GET /patients/:abhaId`
    *   **Response:** `Patient Profile` (if exists)

#### **Prescriptions**

*   **Get All Prescriptions / Search**
    *   **Endpoint:** `GET /prescriptions/:abhaId`
    *   **Query Params:** `?search={query}` (Optional, filters by ID, Patient Name, or Date)
    *   **Response:** `List<Prescription>`

*   **Create Prescription**
    *   **Endpoint:** `POST /prescriptions/`
    *   **Body:** 
        ```json
        {
          "abhaId": "1234-5678-9012-3456",
          "diagnosis": "...",
          "medicines": [...],
          "labTests": [...]
        }
        ```
    *   **Response:** `Prescription`

---

## 3. Patient App APIs

### Base URL: `/api/v1/patient`

#### **My Records**
*   **Get My Prescriptions**
    *   **Endpoint:** `GET /prescriptions`
    *   **Response:** `List<Prescription>` (Filtered by authenticated user's ABHA ID)

*   **Get My Profile**
    *   **Endpoint:** `GET /profile`
    *   **Response:** `User Profile`

---

## 4. Data Structures

### **User (Updated)**
```json
{
  "id": "...",
  "username": "...",
  "email": "...",
  "password": "...", 
  "age": "...",
  "gender": "...",
  "role": "Doctor|Patient|Pharmacist|Pathologist",
  "abhaId": "1234-5678-9012-3456 (Unique for Patients)",
  "aadhaarNumber": " (Optional/Hashed) "
}
```

### **Prescription**
```json
{
  "id": "RX123456",
  "abhaId": "1234-5678-9012-3456",
  "doctorId": "Ref(User)",
  "doctorName": "Dr. Smith",
  "date": "2023-10-27T10:00:00.000Z",
  "diagnosis": "Viral Fever",
  "medicines": [
    {
      "name": "Paracetamol-500mg",
      "medicineId": "Ref(Medicine)",
      "frequency": "1-0-1",
      "duration": "5 days"
    }
  ],
  "labTests": [
    "CBC",
    "Typhoid Test"
  ]
}
```

### **Medicine**
```json
{
  "id": "uuid-v4-string",
  "name": "Amoxicillin-500mg",
  "chemicalFormula": "C16H19N3O4",
}
```

### **MedicalHistory** (Aggregated View)
```json
{
  "abhaId": "1234-5678-9012-3456",
  "records": [
    {
      "prescriptionId": "RX123456",
      "doctorName": "Dr. Smith",
      "date": "2023-10-27T10:00:00.000Z",
      "diagnosis": "Viral Fever",
      "medicines": ["Paracetamol-500mg"]
    }
  ]
}
```
*Note: This is a derived view from `Prescription` collection.*
