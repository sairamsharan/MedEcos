import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/services/database_service.dart';
import '../../../features/medicines/widgets/add_medicine_dialog.dart';
import '../../../features/medicines/screens/medicine_list_screen.dart';
import '../../../features/settings/screens/settings_screen.dart';
import '../../../features/history/screens/history_screen.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../features/doctors/screens/doctors_map_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _db = DatabaseService();
  final PreferencesService _prefs = PreferencesService();
  final NotificationService _notifications = NotificationService();
  List<Medicine> _medicines = [];
  Map<String, String> _timeLabels = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final list = await _db.getMedicines();
      Map<String, String> labels = {};
      
      for (var med in list) {
        await _notifications.scheduleMedicineReminders(med); // Reschedule alarms for loaded data
        
        if (med.timings.isNotEmpty) {
           List<String> timeStrings = [];
           for (var t in med.timings) {
             final time = await _prefs.calculateExactTime(t);
             final timeStr = DateFormat('h:mm a').format(time);
             
             // Time label like "After Meal"
             final typeName = t.timeType.name.replaceAll(RegExp(r'(?=[A-Z])'), ' ');
             // Meal label like "LUNCH"
             final mealName = t.mealRef.name.toUpperCase();
             
             timeStrings.add('$timeStr ($typeName $mealName)');
           }
           labels[med.id] = timeStrings.join(', ');
        }
      }

      setState(() {
        _medicines = list;
        _timeLabels = labels;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Find next medicine (logic simplified for demo: just pick first for now or random)
    // In real app, calculate closest time based on meal times.
    Medicine? nextMedicine;
    if (_medicines.isNotEmpty) {
      nextMedicine = _medicines.first; 
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MedEcos Patient'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              _loadData(); // Reload in case meal times changed affecting schedule (visual only here)
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(),
                    const SizedBox(height: 16),
                    _buildFindDoctorsCard(context),
                    const SizedBox(height: 16),
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
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => const AddMedicineDialog(),
          );
          _loadData();
        },
        child: const Icon(Icons.add),
      ),
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

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting = "Good Morning";
    if (hour >= 12 && hour < 17) {
      greeting = "Good Afternoon";
    } else if (hour >= 17) {
      greeting = "Good Evening";
    }

    return Text(
      "$greeting, Patient",
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCurrentMedicineCard(Medicine medicine) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightBlue.shade50, // Light blue bg
        border: Border.all(color: Colors.blue.shade900, width: 2), // Dark blue border
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
            onPressed: () {
               // Log as taken
               _db.logMetadata(medicine.id, medicine.name, DateTime.now(), 'TAKEN');
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as taken')));
            },
            child: const Text("Mark as Taken"),
          )
        ],
      ),
    );
  }
}
