import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/pdf_service.dart';
import '../../../core/models/prescription_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/utils/medicine_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
  final Set<String> _selectedTimings = {'Morning'};
  String _selectedContext = 'After Food';
  String _selectedInstructions = 'None';
  String _selectedDuration = '5 Days';

  final List<String> _timings = ['Morning', 'Afternoon', 'Evening', 'Night'];
  final List<String> _contexts = ['After Food', 'Before Food', 'With Food', 'Empty Stomach'];
  final List<String> _instructions = ['None', 'With Warm Water', 'With Milk', 'Chewable', 'Dissolve in water'];
  final List<String> _durations = ['1 Day', '2 Days', '3 Days', '5 Days', '1 Week', '2 Weeks', '1 Month', '3 Months', 'Ongoing'];

  // Dummy Data
  final List<String> _labTests = [
    'Complete Blood Count (CBC)', 'Lipid Profile', 'Liver Function Test (LFT)', 
    'Kidney Function Test (KFT)', 'Blood Sugar Fasting', 'Blood Sugar PP', 
    'HbA1c', 'Thyroid Profile', 'Urine Routine', 'X-Ray Chest', 'ECG', 'USG Abdomen'
  ];

  List<String> _allMedicines = [];
  bool _loadingMedicines = true;

  @override
  void initState() {
    super.initState();
    _fetchMedicines();
  }

  Future<void> _fetchMedicines() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5000/api/public/medicines'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _allMedicines = data.map((e) => e['name'].toString()).toList();
            _loadingMedicines = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMedicines = false);
      }
    }
  }

  Future<void> _addMedicine() async {
    final newMedicineName = _medicineSearchController.text.trim();
    if (newMedicineName.isEmpty) return;
    if (_selectedTimings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select at least one timing")));
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Get current patient's meds from data service to include in the list of what they are already taking
    final patientId = widget.patientId;
    final patientPrescriptions = ApiService().getPrescriptionsForPatient(patientId);
    final currentMedsSet = <String>{};
    
    // Process all past prescriptions to find currently ACTIVE medicines
    for (var prescription in patientPrescriptions) {
      for (var med in prescription.medicines) {
        if (med['name'] != null && med['duration'] != null) {
          if (MedicineUtils.isActiveMedicine(prescription.date, med['duration']!)) {
            currentMedsSet.add(med['name']!);
          }
        }
      }
    }

    // Include medicines already added to THIS form but not saved yet.
    final addingMedicinesSet = _medicines.map((m) => m['name']!).toSet();
    
    // The prompt expects we are adding $newMedicine to the overall mix.
    // If the patient is already taking Aspirin, and the doctor is adding Aspirin to this form, then testing Ibuprofen.
    final allCurrentMedsList = {...currentMedsSet, ...addingMedicinesSet}.toList();

    final result = await GeminiService.checkMedicineClashes(allCurrentMedsList, newMedicineName);

    if (mounted) Navigator.pop(context); // Close loading

    if (result != null && result.startsWith('CLASH:')) {
      if (!mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("⚠️ Potential Drug Interaction"),
          content: Text(result.substring(6).trim()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Add Anyway", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    } else if (result != null && result.startsWith('Error:')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
      }
      return; 
    }

    setState(() {
      _medicines.add({
        'name': newMedicineName,
        'timing': _selectedTimings.join(', '),
        'context': _selectedContext,
        'instruction': _selectedInstructions,
        'duration': _selectedDuration,
      });
      _medicineSearchController.clear();
      _selectedInstructions = 'None'; 
      _selectedTimings.clear();
      _selectedTimings.add('Morning');
      _selectedDuration = '5 Days';
    });
  }

  void _addLabTest() {
    if (_labTestSearchController.text.isNotEmpty && !_selectedLabTests.contains(_labTestSearchController.text)) {
      setState(() {
        _selectedLabTests.add(_labTestSearchController.text);
        _labTestSearchController.clear();
      });
    }
  }


  Future<void> _savePrescription() async {
    if (_medicines.isEmpty && _selectedLabTests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add at least one medicine or lab test")));
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final doctorName = prefs.getString('username') ?? 'Dr. Tanishq';
      // Generate ID
      final String prescriptionId = "PRES-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

      // Create Model
      final prescription = Prescription(
        id: prescriptionId,
        patientId: widget.patientId,
        patientName: widget.patientName,
        doctorName: doctorName,
        date: DateTime.now(),
        diagnosis: _symptomsController.text,
        medicines: List.from(_medicines),
        labTests: List.from(_selectedLabTests),
      );

      // Save to Service
      await ApiService().addPrescription(prescription);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Prescription Saved Successfully")));
      
      // Navigate back after saving
      Navigator.pop(context, true); // Pass true to signal refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _printPrescription() async {
    if (_medicines.isEmpty && _selectedLabTests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add at least one medicine or lab test to print")));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generating PDF...")));
    final String date = DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.now());
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final doctorName = prefs.getString('username') ?? 'Dr. Tanishq';
      await PdfService.generateAndPrintPrescription(
        doctorName: doctorName,
        patientName: widget.patientName,
        patientId: widget.patientId,
        symptoms: _symptomsController.text,
        medicines: List.from(_medicines),
        labTests: List.from(_selectedLabTests),
        date: date,
        doctorSpeciality: prefs.getString('speciality') ?? 'General Physician',
        clinicLocation: prefs.getString('location') ?? 'MedEcos Clinic Network',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error printing: $e")));
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
                  
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      return _allMedicines.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      _medicineSearchController.text = selection;
                    },
                    fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                      // Keep the external controller in sync so the "Add Medicine to List" button works
                      textEditingController.addListener(() {
                        _medicineSearchController.text = textEditingController.text;
                      });
                      
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Search or Type Medicine Name',
                          prefixIcon: Icon(Icons.medication),
                        ),
                        onSubmitted: (String value) {
                          onFieldSubmitted();
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return _buildOptionsView(context, onSelected, options);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Dosage Controls
                  const Text("Select Timings", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _timings.map((timing) {
                      final isSelected = _selectedTimings.contains(timing);
                      return FilterChip(
                        label: Text(timing),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedTimings.add(timing);
                            } else {
                              // Ensure at least one is selected? Let's just allow deselect for now.
                              _selectedTimings.remove(timing);
                            }
                          });
                        },
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        checkmarkColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedContext,
                          items: _contexts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setState(() => _selectedContext = v!),
                          decoration: const InputDecoration(labelText: "Context"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedDuration,
                          items: _durations.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setState(() => _selectedDuration = v!),
                          decoration: const InputDecoration(labelText: "Duration"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Special Instructions (Fixed Dropdown)
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
                          subtitle: Text("${med['timing']} • ${med['context']} • ${med['duration']}\nNote: ${med['instruction']}"),
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
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _printPrescription,
                          icon: const Icon(Icons.print),
                          label: const Text("Print"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _savePrescription,
                          icon: const Icon(Icons.save),
                          label: const Text("Save"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                        ),
                      ),
                    ],
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
