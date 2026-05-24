import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/data_service.dart';
import '../../../core/models/patient_model.dart';
import 'patient_details_screen.dart';
import '../widgets/add_patient_dialog.dart';

class PatientLookupScreen extends StatefulWidget {
  const PatientLookupScreen({super.key});

  @override
  State<PatientLookupScreen> createState() => _PatientLookupScreenState();
}

class _PatientLookupScreenState extends State<PatientLookupScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _navigateToDetails(String patientId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailsScreen(patientId: patientId),
      ),
    );
  }

  void _showAddPatientDialog() async {
    final result = await showDialog<Patient>(
      context: context,
      builder: (context) => const AddPatientDialog(),
    );
    
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Patient ${result.name} registered successfully!")),
      );
    }
  }

  Widget _buildOptionsView(BuildContext context, AutocompleteOnSelected<Patient> onSelected, Iterable<Patient> options) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 8.0,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300, maxWidth: 400),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final Patient patient = options.elementAt(index);
              return InkWell(
                onTap: () => onSelected(patient),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          patient.name[0],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "ID: ${patient.id} • ${patient.age} Yrs • ${patient.gender}",
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    ],
                  ),
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
      appBar: AppBar(
        title: const Text("Patient Lookup"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddPatientDialog,
            tooltip: "Register New Patient",
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side - Centered Search Card
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.medical_information, size: 48, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      "Find Patient",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Start typing to search, scan QR, or register new patient",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    // Autocomplete Search
                    Autocomplete<Patient>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<Patient>.empty();
                        }
                        return DataService().searchPatients(textEditingValue.text);
                      },
                      displayStringForOption: (Patient patient) => patient.name,
                      optionsViewBuilder: _buildOptionsView,
                      onSelected: (Patient patient) {
                        _navigateToDetails(patient.id);
                      },
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: "Patient ID or Name",
                            hintText: "Start typing...",
                            prefixIcon: Icon(Icons.person_search),
                            border: OutlineInputBorder(),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("QR Scanner: Simulating patient lookup..."))
                              );
                              final patients = DataService().patients;
                              if (patients.isNotEmpty) {
                                _navigateToDetails(patients.first.id);
                              }
                            },
                            icon: const Icon(Icons.qr_code_scanner, size: 20),
                            label: const Text("QR Scan"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showAddPatientDialog,
                            icon: const Icon(Icons.person_add, size: 20),
                            label: const Text("New Patient"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: AppColors.accent),
                              foregroundColor: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Right Side - Recent Patients Section
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Recent Patients",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: DataService().patients.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final patient = DataService().patients[index];
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                patient.name[0],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(patient.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("ID: ${patient.id} • ${patient.age} Yrs • ${patient.gender}"),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _navigateToDetails(patient.id),
                          ),
                        );
                      },
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
