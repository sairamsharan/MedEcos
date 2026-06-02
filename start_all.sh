#!/bin/bash

# Ensure we exit on failure but also clean up background processes
trap "kill 0" EXIT

echo "======================================"
echo "    Starting MedEcos Ecosystem        "
echo "======================================"

cd "$(dirname "$0")"

echo "1. Starting Backend & Seeding Database..."
cd Backend
npm install
node src/seed.js
npm run dev &
BACKEND_PID=$!
cd ..

echo "2. Starting Patient Portal (Port 3001)..."
cd Frontend/med_ecos_patient
flutter run -d web-server --web-port 3001 &
cd ../..

echo "3. Starting Doctor Portal (Port 3002)..."
cd Frontend/med_ecos_doctor
flutter run -d web-server --web-port 3002 &
cd ../..

echo "4. Starting Pharmacist Portal (Port 3003)..."
cd Frontend/med_ecos_pharmacist
flutter run -d web-server --web-port 3003 &
cd ../..

echo "5. Serving Landing Page (Port 3000)..."
cd Frontend
python3 -m http.server 3000 &
cd ..

echo "======================================"
echo " All services are starting up! "
echo " Please wait ~30 seconds for Flutter to compile."
echo " "
echo " 👉 Open: http://localhost:3000 "
echo "======================================"

# Keep the script running to hold background processes
wait
