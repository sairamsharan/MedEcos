import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/medicine_model.dart';
import '../../../features/medicines/screens/medicine_list_screen.dart';
import '../../../features/settings/screens/settings_screen.dart';
import '../../../features/history/screens/history_screen.dart';
import '../../../features/appointments/screens/appointments_screen.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../features/doctors/screens/doctors_map_screen.dart';
import '../../prescriptions/screens/prescriptions_screen.dart';
import '../../lab_tests/screens/patient_lab_orders_screen.dart';
import '../widgets/sidebar.dart';
import '../widgets/header.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PreferencesService _prefs = PreferencesService();
  final NotificationService _notifications = NotificationService();
  
  List<Medicine> _medicines = [];
  Map<String, String> _timeLabels = {};
  bool _loading = true;
  String? _error;
  int _selectedIndex = 0;
  
  int _activeMedicines = 0;
  int _totalPrescriptions = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final List<dynamic> prescriptions = await ApiService().getPrescriptions();
      List<Medicine> parsedMedicines = [];
      
      for (var p in prescriptions) {
        if (p['fullMedicines'] != null) {
          for (var m in p['fullMedicines']) {
            final freqStr = m['frequency']?.toString().toLowerCase() ?? '';
            int freq = 1;
            if (freqStr.contains('twice') || freqStr.contains('bid') || freqStr.contains('2')) freq = 2;
            if (freqStr.contains('thrice') || freqStr.contains('tid') || freqStr.contains('3')) freq = 3;
            
            parsedMedicines.add(Medicine(
              id: m['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              name: m['name'] ?? 'Unknown Medicine',
              dosage: m['dosage'] ?? '',
              frequency: freq,
              timings: [], // Real prescriptions don't have local timings yet, would need a UI to let patient set them
              startDate: DateTime.now(),
            ));
          }
        }
      }
      
      // We will skip scheduling local notifications for now since backend doesn't have timings
      Map<String, String> labels = {};

      if (mounted) {
        setState(() {
          _medicines = parsedMedicines;
          _timeLabels = labels;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
    await _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('patient_jwt_token') ?? '';
      
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/v1/patient/dashboard-stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _activeMedicines = data['activeMedicines'] ?? 0;
            _totalPrescriptions = data['totalPrescriptions'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch stats: $e');
    }
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) _loadData();
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardOverview();
      case 1:
        return const PrescriptionsScreen();
      case 2:
        return const AppointmentsScreen();
      case 3:
        return const HistoryScreen();
      case 4:
        return const PatientLabOrdersScreen();
      case 5:
        return const SettingsScreen();
      default:
        return const Center(child: Text("Coming Soon"));
    }
  }

  Widget _buildDashboardOverview() {
    Medicine? nextMedicine;
    if (_medicines.isNotEmpty) {
      nextMedicine = _medicines.first; 
    }

    final Widget homeContent = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
            : SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dashboard",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 24),
                // Stats Grid
                Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    StatCard(title: "Medicines", value: _medicines.length.toString(), icon: Icons.medical_services, color: Colors.blue),
                    StatCard(title: "Next Dose", value: nextMedicine?.name ?? "None", icon: Icons.access_time, color: Colors.orange),
                    StatCard(title: "Active Meds", value: _activeMedicines.toString(), icon: Icons.healing, color: Colors.teal),
                    StatCard(title: "Prescriptions", value: _totalPrescriptions.toString(), icon: Icons.receipt_long, color: Colors.green),
                  ],
                ),
                const SizedBox(height: 32),
                _buildFindDoctorsCard(context),
                const SizedBox(height: 32),
                if (nextMedicine != null) _buildCurrentMedicineCard(nextMedicine),
                if (nextMedicine == null) 
                  const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("No medicines scheduled"))),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Medicines',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () async {
                         await Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicineListScreen()));
                         _loadData();
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ..._medicines.map((m) => Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(m.name[0])),
                    title: Text(m.name),
                    subtitle: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('${m.dosage} • ${m.frequency}x daily'),
                         if (_timeLabels.containsKey(m.id))
                           Text(_timeLabels[m.id]!, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                       ],
                    ),
                  ),
                )).toList(),
              ],
            ),
          );

    return Column(
      children: [
        const Header(),
        Expanded(child: homeContent),
      ],
    );
  }

  Widget _buildFindDoctorsCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DoctorsMapScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.map_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Find Nearby Doctors',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Verified doctors near you on map',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMedicineCard(Medicine medicine) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightBlue.shade50,
        border: Border.all(color: Colors.blue.shade900, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Current Medicine",
            style: TextStyle(
              color: Colors.blue.shade900,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "${medicine.name} ${medicine.dosage}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          if (_timeLabels.containsKey(medicine.id))
            Text(
              _timeLabels[medicine.id]!,
              style: const TextStyle(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.bold),
            ),
            
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
               try {
                 await ApiService().logMedicineHistory(medicine.id, medicine.name, DateTime.now(), 'TAKEN');
                 if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as taken')));
                 }
               } catch (e) {
                 if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to mark as taken: $e')));
                 }
               }
            },
            child: const Text("Mark as Taken"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          SizedBox(
            width: 250, 
            child: Sidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: _onItemSelected,
            ),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }
}
