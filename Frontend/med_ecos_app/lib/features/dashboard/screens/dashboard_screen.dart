import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/services/api_service.dart';

// Common Widgets
import '../widgets/sidebar.dart';
import '../widgets/header.dart';
import '../widgets/stat_card.dart';
import '../widgets/active_medicines_list.dart';

// Patient Screens
import '../../../features/medicines/screens/medicine_list_screen.dart';
import '../../../features/history/screens/history_screen.dart';
import '../../../features/doctors/screens/doctors_map_screen.dart';
import '../../prescriptions/screens/prescriptions_screen.dart';
import '../../../features/profile/screens/profile_screen.dart' as patient_profile;
import '../../../features/appointments/screens/appointments_screen.dart' as patient_appointments;

// Doctor Screens
import '../../../features/prescription/screens/doctor_prescription_list_screen.dart' as doctor_prescription;
import '../../../features/patient_lookup/screens/doctor_patient_lookup_screen.dart' as doctor_patient_lookup;
import '../../../features/appointments/screens/doctor_appointments_screen.dart';
import '../../../features/profile/screens/doctor_profile_screen.dart' as doctor_profile;

// Pharmacist Screens
import '../../../features/prescription/screens/pharmacist_prescription_list_screen.dart' as pharmacist_prescription;
import '../../../features/patient_lookup/screens/pharmacist_patient_lookup_screen.dart' as pharmacist_patient_lookup;
import '../../../features/dashboard/screens/inventory_screen.dart';
import '../../../features/profile/screens/pharmacist_profile_screen.dart' as pharmacist_profile;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userRole = 'Patient';
  int _selectedIndex = 0;
  bool _loading = true;

  // Patient Stats
  List<Medicine> _medicines = [];
  int _activeMedicines = 0;
  int _totalPrescriptions = 0;

  // Doctor & Pharmacist Stats
  int _prescriptionsToday = 0;
  int _pendingOrders = 0;
  int _totalCustomers = 0;

  @override
  void initState() {
    super.initState();
    _loadRoleAndData();
  }

  Future<void> _loadRoleAndData() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'Patient';
    setState(() {
      _userRole = role;
    });

    if (role == 'Patient') {
      await _fetchPatientData();
    } else {
      await _fetchProStats();
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _fetchPatientData() async {
    try {
      final List<dynamic> prescriptions = await ApiService().getPrescriptions();
      List<Medicine> parsedMedicines = [];
      for (var p in prescriptions) {
        if (p['fullMedicines'] != null) {
          for (var m in p['fullMedicines']) {
            parsedMedicines.add(Medicine(
              id: m['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              name: m['name'] ?? 'Unknown',
              dosage: m['dosage'] ?? '',
              frequency: 1,
              timings: [],
              startDate: DateTime.now(),
            ));
          }
        }
      }
      final stats = await ApiService().getDashboardStats();
      if (mounted) {
        setState(() {
          _medicines = parsedMedicines;
          _activeMedicines = stats['activeMedicines'] ?? 0;
          _totalPrescriptions = stats['totalPrescriptions'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _fetchProStats() async {
    try {
      await ApiService().loadData(); // Ensure patients and prescriptions are loaded
      final stats = await ApiService().getDashboardStats();
      if (mounted) {
        setState(() {
          _prescriptionsToday = stats['prescriptionsToday'] ?? stats['appointmentsToday'] ?? 0;
          _pendingOrders = stats['pendingOrders'] ?? stats['pendingReports'] ?? 0;
          _totalCustomers = stats['totalCustomers'] ?? stats['totalPatients'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching pro stats: $e');
    }
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildContent() {
    if (_userRole == 'Patient') {
      switch (_selectedIndex) {
        case 0: return _buildPatientDashboard();
        case 1: return const PrescriptionsScreen();
        case 2: return const patient_appointments.AppointmentsScreen();
        case 3: return const HistoryScreen();
        case 4: return const patient_profile.ProfileScreen();
        default: return const Center(child: Text("Coming Soon"));
      }
    } else if (_userRole == 'Doctor') {
      switch (_selectedIndex) {
        case 0: return _buildProDashboard();
        case 1: return const doctor_prescription.PrescriptionListScreen();
        case 2: return const doctor_patient_lookup.PatientLookupScreen();
        case 3: return const AppointmentsScreen();
        case 4: return const doctor_profile.ProfileScreen();
        default: return const Center(child: Text("Coming Soon"));
      }
    } else if (_userRole == 'Pharmacist') {
      switch (_selectedIndex) {
        case 0: return _buildProDashboard();
        case 1: return const pharmacist_prescription.PrescriptionListScreen();
        case 2: return const pharmacist_patient_lookup.PatientLookupScreen();
        case 3: return const InventoryScreen();
        case 4: return const pharmacist_profile.ProfileScreen();
        default: return const Center(child: Text("Coming Soon"));
      }
    }
    return const Center(child: Text("Unknown Role"));
  }

  Widget _buildPatientDashboard() {
    return Column(
      children: [
        const Header(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Patient Dashboard", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 24, runSpacing: 24,
                  children: [
                    StatCard(title: "Medicines", value: _medicines.length.toString(), icon: Icons.medical_services, color: Colors.blue, onTap: () => _onItemSelected(3)),
                    StatCard(title: "Active Meds", value: _activeMedicines.toString(), icon: Icons.healing, color: Colors.teal, onTap: () => _onItemSelected(3)),
                    StatCard(title: "Prescriptions", value: _totalPrescriptions.toString(), icon: Icons.receipt_long, color: Colors.green, onTap: () => _onItemSelected(1)),
                  ],
                ),
                const SizedBox(height: 32),
                ActiveMedicinesList(medicines: _medicines),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProDashboard() {
    return Column(
      children: [
        const Header(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$_userRole Dashboard", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 24, runSpacing: 24,
                  children: [
                    StatCard(title: "Prescriptions Today", value: _prescriptionsToday.toString(), icon: Icons.receipt_long, color: Colors.blue, onTap: () => _onItemSelected(1)),
                    StatCard(title: "Pending Action", value: _pendingOrders.toString(), icon: Icons.pending_actions, color: Colors.orange, onTap: () => _onItemSelected(3)),
                    StatCard(title: "Total Customers/Patients", value: _totalCustomers.toString(), icon: Icons.people, color: Colors.teal, onTap: () => _onItemSelected(2)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          SizedBox(
            width: 250, 
            child: Sidebar(
              userRole: _userRole,
              selectedIndex: _selectedIndex,
              onItemSelected: _onItemSelected,
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }
}
