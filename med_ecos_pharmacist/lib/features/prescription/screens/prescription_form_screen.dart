import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/pdf_service.dart';
import '../../../core/models/prescription_model.dart';
import '../../../core/services/data_service.dart';

class PrescriptionFormScreen extends StatefulWidget {
  final String patientId; // Pass patient info
  final String patientName;

  const PrescriptionFormScreen({super.key, required this.patientId, required this.patientName});

  @override
  State<PrescriptionFormScreen> createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  final List<Map<String, String>> _medicines = [];
  final List<String> _selectedLabTests = [];

  // Form Controllers
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _medicineSearchController = TextEditingController();
  final TextEditingController _labTestSearchController = TextEditingController();

  
  // Dosage Selections
  String _selectedTiming = 'Morning';
  String _selectedContext = 'After Food';
  String _selectedInstructions = 'None';

  final List<String> _timings = ['Morning', 'Afternoon', 'Evening', 'Night', '2 Times/Day', '3 Times/Day'];
  final List<String> _contexts = ['After Food', 'Before Food', 'With Food', 'Empty Stomach'];
  final List<String> _instructions = ['None', 'With Warm Water', 'With Milk', 'Chewable', 'Dissolve in water'];

  // Dummy Data
  final List<String> _labTests = [
    'Complete Blood Count (CBC)', 'Lipid Profile', 'Liver Function Test (LFT)', 
    'Kidney Function Test (KFT)', 'Blood Sugar Fasting', 'Blood Sugar PP', 
    'HbA1c', 'Thyroid Profile', 'Urine Routine', 'X-Ray Chest', 'ECG', 'USG Abdomen'
  ];

  // Dummy Medicine List
  final List<String> _allMedicines = [
    'Paracetamol 500mg', 'Amoxicillin 250mg', 'Cetirizine 10mg', 'Ibuprofen 400mg', 
    'Omeprazole 20mg', 'Metformin 500mg', 'Atorvastatin 10mg', 'Aspirin 75mg'
  ];

  void _addMedicine() {
    if (_medicineSearchController.text.isNotEmpty) {
      setState(() {
        _medicines.add({
          'name': _medicineSearchController.text,
          'timing': _selectedTiming,
          'context': _selectedContext,
          'instruction': _selectedInstructions,
        });
        _medicineSearchController.clear();
        _selectedInstructions = 'None'; 
      });
    }
  }

  void _addLabTest() {
    if (_labTestSearchController.text.isNotEmpty && !_selectedLabTests.contains(_labTestSearchController.text)) {
      setState(() {
        _selectedLabTests.add(_labTestSearchController.text);
        _labTestSearchController.clear();
      });
    }
  }


  void _generatePrescription() async {
    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add at least one medicine")));
      return;
    }

    try {
      // Generate ID
      final String prescriptionId = "PRES-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
      final String date = DateTime.now().toString().split(' ')[0];

      // Create Model
      final prescription = Prescription(
        id: prescriptionId,
        patientId: widget.patientId,
        patientName: widget.patientName,
        pharmacistName: "Pharm. Sairam",
        date: DateTime.now(),
        diagnosis: _symptomsController.text,
        medicines: List.from(_medicines),
        labTests: List.from(_selectedLabTests),
      );

      // Save to Service
      DataService().addPrescription(prescription);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Prescription Saved Successfully")));

      // Generate PDF
      await PdfService.generateAndPrintPrescription(
        pharmacistName: prescription.pharmacistName,
        patientName: widget.patientName,
        patientId: widget.patientId,
        symptoms: prescription.diagnosis,
        medicines: prescription.medicines,
        labTests: prescription.labTests,
        date: date,
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget _buildOptionsView(BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 250, maxWidth: 400),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final String option = options.elementAt(index);
              return InkWell(
                onTap: () => onSelected(option),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(option),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Write Prescription")),
      body: Row(
        children: [
          // Left Side: Form
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Patient: ${widget.patientName} (${widget.patientId})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 24),
                  
                  // Symptoms
                  TextField(
                    controller: _symptomsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Symptoms / Diagnosis",
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  Text("Add Medicine", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Medicine Search (Allows custom)
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      return _allMedicines.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    optionsViewBuilder: _buildOptionsView,
                    onSelected: (String selection) {
                       setState(() {
                        _medicineSearchController.text = selection;
                       });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      // Ensure the initial value is synced
                      if (controller.text != _medicineSearchController.text) {
                        controller.text = _medicineSearchController.text;
                      }
                      return TextField(
                        controller: controller, // Use the Autocomplete controller
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        decoration: const InputDecoration(
                          labelText: "Medicine Name (Select or Type New)",
                          prefixIcon: Icon(Icons.medication),
                        ),
                        onChanged: (val) {
                           _medicineSearchController.text = val;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Dosage Controls
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedTiming,
                          items: _timings.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setState(() => _selectedTiming = v!),
                          decoration: const InputDecoration(labelText: "Timing"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedContext,
                          items: _contexts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setState(() => _selectedContext = v!),
                          decoration: const InputDecoration(labelText: "Context"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Special Instructions
                  Autocomplete<String>(
                    initialValue: TextEditingValue(text: _selectedInstructions == 'None' ? '' : _selectedInstructions),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      return _instructions.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    optionsViewBuilder: _buildOptionsView,
                    onSelected: (String selection) {
                      setState(() {
                         _selectedInstructions = selection;
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        decoration: const InputDecoration(
                          labelText: "Special Instructions",
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        onChanged: (val) {
                           _selectedInstructions = val;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton.icon(
                    onPressed: _addMedicine,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Medicine"),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  Text("Lab Tests", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Lab Test Search
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') return const Iterable<String>.empty();
                      return _labTests.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    optionsViewBuilder: _buildOptionsView,
                    onSelected: (String selection) {
                       setState(() {
                        _labTestSearchController.text = selection;
                       });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      if (controller.text != _labTestSearchController.text) {
                        controller.text = _labTestSearchController.text;
                      }
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        decoration: const InputDecoration(
                          labelText: "Lab Test Name",
                          prefixIcon: Icon(Icons.science),
                        ),
                        onChanged: (val) {
                           _labTestSearchController.text = val;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addLabTest,
                    icon: const Icon(Icons.add_task),
                    label: const Text("Add Lab Test"),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: AppColors.accent),
                  ),
                ],
              ),
            ),
          ),
          
          // Right Side: Preview List
          Expanded(
            flex: 1,
            child: Container(
              color: AppColors.surfaceVariant.withOpacity(0.3),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Prescription Preview", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _medicines.length,
                      separatorBuilder: (c, i) => const Divider(),
                      itemBuilder: (context, index) {
                        final med = _medicines[index];
                        return ListTile(
                          title: Text(med['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${med['timing']} • ${med['context']}\nNote: ${med['instruction']}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.error),
                            onPressed: () => setState(() => _medicines.removeAt(index)),
                          ),
                          isThreeLine: true,
                        );
                      },

                    ),
                  ),
                  
                  if (_selectedLabTests.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text("Lab Tests", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: _selectedLabTests.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.science, size: 16, color: AppColors.textSecondary),
                            title: Text(_selectedLabTests[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => setState(() => _selectedLabTests.removeAt(index)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _generatePrescription,
                    icon: const Icon(Icons.print),
                    label: const Text("Generate & Print"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
