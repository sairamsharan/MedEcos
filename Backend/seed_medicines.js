const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Medicine = require('./src/models/Medicine');

dotenv.config();

const famousMedicines = [
  { name: 'Paracetamol 500mg', chemicalFormula: 'C8H9NO2' },
  { name: 'Ibuprofen 400mg', chemicalFormula: 'C13H18O2' },
  { name: 'Amoxicillin 250mg', chemicalFormula: 'C16H19N3O5S', doctorOnly: true },
  { name: 'Cetirizine 10mg', chemicalFormula: 'C21H25ClN2O3' },
  { name: 'Omeprazole 20mg', chemicalFormula: 'C17H19N3O3S' },
  { name: 'Azithromycin 500mg', chemicalFormula: 'C38H72N2O12', doctorOnly: true },
  { name: 'Metformin 500mg', chemicalFormula: 'C4H11N5', doctorOnly: true },
  { name: 'Amlodipine 5mg', chemicalFormula: 'C20H25ClN2O5', doctorOnly: true },
  { name: 'Atorvastatin 10mg', chemicalFormula: 'C33H35FN2O5', doctorOnly: true },
  { name: 'Losartan 50mg', chemicalFormula: 'C22H23ClN6', doctorOnly: true },
  { name: 'Pantoprazole 40mg', chemicalFormula: 'C16H15F2N3O4S' },
  { name: 'Dolo 650mg', chemicalFormula: 'C8H9NO2' },
  { name: 'Vitamin C 500mg', chemicalFormula: 'C6H8O6' },
  { name: 'Vitamin D3 60K IU', chemicalFormula: 'C27H44O' },
  { name: 'Calcium 500mg', chemicalFormula: 'Ca' },
  { name: 'Zinc 50mg', chemicalFormula: 'Zn' },
  { name: 'Iron 100mg', chemicalFormula: 'Fe' },
  { name: 'Aspirin 75mg', chemicalFormula: 'C9H8O4' },
  { name: 'Diclofenac 50mg', chemicalFormula: 'C14H11Cl2NO2' },
  { name: 'Levocetirizine 5mg', chemicalFormula: 'C21H25ClN2O3' }
];

async function seedMedicines() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('MongoDB Connected');

    for (const med of famousMedicines) {
      const existing = await Medicine.findOne({ name: med.name });
      if (!existing) {
        await Medicine.create(med);
        console.log(`Added ${med.name}`);
      } else {
        console.log(`${med.name} already exists`);
      }
    }

    console.log('Seeding Complete');
    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

seedMedicines();
