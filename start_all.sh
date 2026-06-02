#!/bin/bash

# Ensure we exit on failure but also clean up background processes
trap "kill 0" EXIT

echo "======================================"
echo "    Starting MedEcos Unified App      "
echo "======================================"

cd "$(dirname "$0")"

echo "1. Starting Backend & Seeding Database..."
cd Backend
npm install
node src/seed.js
npm run dev &
BACKEND_PID=$!
cd ..

echo "2. Starting MedEcos Unified App (Port 3000)..."
cd Frontend/med_ecos_app
flutter run -d web-server --web-port 3000 &
cd ../..

echo "======================================"
echo " All services are starting up! "
echo " Please wait ~30 seconds for Flutter to compile."
echo " "
echo " 👉 Open: http://localhost:3000 "
echo "======================================"

# Keep the script running to hold background processes
wait
