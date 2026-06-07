# Backend API & Data Structure Specification (ABHA Enabled)

## 1. Authentication (ABHA & Roles)

### Doctors / Pharmacists / Pathologists
*   **Standard Login**
    *   **Endpoint:** `POST /api/auth/login`
    *   **Body:** `email`, `password`
    *   **Response:** `token`, `user`

### Patients (ABHA Flow)
*   **Generate OTP (Mock)**
    *   **Endpoint:** `POST /api/auth/abha/generate-otp`
    *   **Body:** `abhaId` (e.g., "1234-5678-9012-3456")
    *   **Response:** `transactionId`, `message: "OTP sent to linked mobile"`

*   **Verify OTP & Login**
    *   **Endpoint:** `POST /api/auth/abha/verify-otp`
    *   **Body:** `transactionId`, `otp`, `abhaId`
    *   **Response:** `token`, `user` (creates user if first time)

---

## 2. Doctor App APIs

### Base URL: `/api/v1/doctor`

#### **Patients & Registration**
*   **Search Patient**
    *   **Endpoint:** `GET /patients/:abhaId`
    *   **Response:** `Patient Profile` (if exists)

*   **ABHA Register**
    *   **Endpoint:** `POST /patients/abha-register`
    *   **Body:** `transactionId`, `otp`, `abhaId`
    *   **Response:** `Patient Profile`

*   **Get Doctor's Patients**
    *   **Endpoint:** `GET /patients`
    *   **Response:** `List<Patient Profile>`

#### **Prescriptions**
*   **Get All Prescriptions / Search**
    *   **Endpoint:** `GET /prescriptions/:abhaId`
    *   **Query Params:** `?search={query}` (Optional)
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

*   **Update Prescription Notes**
    *   **Endpoint:** `PUT /prescriptions/:id/notes`
    *   **Body:** `status`, `doctorNotes`

#### **Dashboard & Appointments**
*   **Dashboard Stats**
    *   **Endpoint:** `GET /dashboard-stats`
*   **Get Appointments**
    *   **Endpoint:** `GET /appointments`

---

## 3. Patient App APIs

### Base URL: `/api/v1/patient`

#### **My Records**
*   **Get My Prescriptions**
    *   **Endpoint:** `GET /prescriptions`
    *   **Response:** `MedicalHistory` (Filtered by user's ABHA ID)

*   **Get My Profile**
    *   **Endpoint:** `GET /profile`
    *   **Response:** `User Profile`

#### **History & Appointments**
*   **Log Medicine History**
    *   **Endpoint:** `POST /history`
*   **Get Medicine History**
    *   **Endpoint:** `GET /history`
*   **Get Appointments**
    *   **Endpoint:** `GET /appointments`
*   **Create Appointment**
    *   **Endpoint:** `POST /appointments`

#### **Lab Orders**
*   **Get Labs**
    *   **Endpoint:** `GET /labs`
*   **Create Lab Test Order**
    *   **Endpoint:** `POST /lab-test-orders`
*   **Get Lab Test Orders**
    *   **Endpoint:** `GET /lab-test-orders`

---

## 4. Pharmacist App APIs

### Base URL: `/api/v1/pharmacist`

*   **Dashboard Stats:** `GET /dashboard-stats`
*   **ABHA Register Patient:** `POST /patients/abha-register`
*   **Get Patients:** `GET /patients`
*   **Get Prescriptions:** `GET /prescriptions`
*   **Update Prescription Notes:** `PUT /prescriptions/:id/notes`
*   **Get Inventory:** `GET /inventory`
*   **Add/Update Inventory:** `POST /inventory`
*   **Generate Bill:** `POST /bills`

---

## 5. Pathologist App APIs

### Base URL: `/api/v1/pathologist`

*   **Get Lab Tests for Patient:** `GET /patients/:abhaId/lab-tests`
*   **Process Test:** `POST /patients/:abhaId/process-test`
*   **Get Orders:** `GET /orders`
*   **Update Order Status:** `PUT /orders/:id/status`

---

## 6. Public APIs

### Base URL: `/api/public`

*   **Verify Prescription Signature:** `GET /verify-prescription/:id`
*   **Get Prescriptions by ABHA:** `GET /prescriptions/patient/:abhaId`
*   **Get Single Prescription:** `GET /prescriptions/:id`
*   **Get Doctors:** `GET /doctors`
*   **Get Medicines:** `GET /medicines`

---

## 7. Data Structures

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
      "duration": "5 days",
      "timing": "After Meal"
    }
  ],
  "labTests": [
    "CBC",
    "Typhoid Test"
  ],
  "digitalSignature": "base64_encoded_signature",
  "signaturePayload": "exact_json_string_signed"
}
```
