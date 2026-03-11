# Backend API & Data Structure Specification

## 1. Doctor App APIs

### Base URL: `/api/v1/doctor`

#### **Patients**

*   **Get All Patients / Search**
    *   **Endpoint:** `GET /patients`
    *   **Query Params:** `?search={query}` (Optional, filters by name or ID)
    *   **Response:** `List<Patient>`

*   **Get Patient Details**
    *   **Endpoint:** `GET /patients/{id}`
    *   **Response:** `Patient`

*   **Add Patient**
    *   **Endpoint:** `POST /patients`
    *   **Body:** `Patient` (without ID, or with ID if client-generated)
    *   **Response:** `Patient` (with assigned ID)

#### **Prescriptions**

*   **Get All Prescriptions / Search**
    *   **Endpoint:** `GET /prescriptions`
    *   **Query Params:** `?search={query}` (Optional, filters by ID, Patient Name, or Date)
    *   **Response:** `List<Prescription>`

*   **Create Prescription**
    *   **Endpoint:** `POST /prescriptions`
    *   **Body:** `Prescription`
    *   **Response:** `Prescription`

---

## 2. Patient App APIs

### Base URL: `/api/v1/patient`

*Note: The Patient app currently runs local-first (SQLite). These APIs would be used for cloud sync or doctor visibility.*

#### **Medicines (Sync)**

*   **Get Medicines**
    *   **Endpoint:** `GET /{patientId}/medicines`
    *   **Response:** `List<Medicine>`

*   **Add/Update Medicine**
    *   **Endpoint:** `POST /{patientId}/medicines`
    *   **Body:** `Medicine`
    *   **Response:** `Medicine`

*   **Delete Medicine**
    *   **Endpoint:** `DELETE /{patientId}/medicines/{medicineId}`
    *   **Response:** `200 OK`

#### **Adherence History**

*   **Log Intake**
    *   **Endpoint:** `POST /{patientId}/history`
    *   **Body:** `HistoryLog`
    *   **Response:** `200 OK`

*   **Get History**
    *   **Endpoint:** `GET /{patientId}/history`
    *   **Response:** `List<HistoryLog>`

#### **Profile & Settings**

*   **Get Profile**
    *   **Endpoint:** `GET /{patientId}/profile`
    *   **Response:** `Patient`

*   **Update Meal Times**
    *   **Endpoint:** `PUT /{patientId}/meal-times`
    *   **Body:** `Map<String, String>` (e.g., `{"breakfast": "08:00", ...}`)
    *   **Response:** `200 OK`

---

## 3. JSON Data Structures

### **Patient**
```json
{
  "id": "P001",
  "name": "John Doe",
  "age": 34,
  "gender": "Male",
  "contact": "9876543210"
}
```

### **Prescription**
```json
{
  "id": "RX123456",
  "patientId": "P001",
  "patientName": "John Doe",
  "doctorName": "Dr. Smith",
  "date": "2023-10-27T10:00:00.000Z",
  "diagnosis": "Viral Fever",
  "medicines": [
    {
      "name": "Paracetamol",
      "dosage": "500mg",
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
  "name": "Amoxicillin",
  "dosage": "250mg",
  "frequency": 2,
  "timings": [
    {
      "timeType": 1, 
      "mealRef": 0, 
      "offsetMinutes": 30
    },
    {
      "timeType": 1,
      "mealRef": 3,
      "offsetMinutes": 30
    }
  ],
  "startDate": "2023-10-27T00:00:00.000Z",
  "endDate": "2023-11-01T00:00:00.000Z" 
}
```
*Note: `endDate` is optional (nullable).*

### **MedicineTiming**
Used within the `Medicine` structure.
```json
{
  "timeType": 1, 
  "mealRef": 0, 
  "offsetMinutes": 30
}
```
*   **timeType**: Enum Integer (`0: beforeMeal`, `1: afterMeal`, `2: emptyStomach`)
*   **mealRef**: Enum Integer (`0: breakfast`, `1: lunch`, `2: snack`, `3: dinner`)
*   **offsetMinutes**: Integer (e.g., `30` or `-30`)

### **HistoryLog**
```json
{
  "id": "log-id-123",
  "medicineId": "uuid-v4-string",
  "medicineName": "Paracetamol",
  "takenTime": "2023-10-27T08:35:00.000Z",
  "status": "Taken" 
}
```
*   **status**: String (e.g., `"Taken"`, `"Skipped"`, `"Missed"`)

### **MealTimes**
```json
{
  "breakfast": "08:00",
  "lunch": "13:00",
  "snack": "17:00",
  "dinner": "20:00"
}
```
