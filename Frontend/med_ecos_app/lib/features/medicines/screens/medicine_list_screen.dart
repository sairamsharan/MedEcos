import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/preferences_service.dart';

class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  final PreferencesService _prefs = PreferencesService();
  List<Medicine> _medicines = [];
  Map<String, String> _timeLabels = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
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
              timings: [], 
              startDate: DateTime.now(),
            ));
          }
        }
      }

      setState(() {
        _medicines = parsedMedicines;
        // _timeLabels = labels; (No timings from backend yet)
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
    return Scaffold(
      appBar: AppBar(title: const Text('Medicines')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : ListView.builder(
              itemCount: _medicines.length,
              itemBuilder: (context, index) {
                final med = _medicines[index];
                return ListTile(
                  title: Text(med.name),
                  subtitle: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text('${med.dosage} • ${med.frequency}x daily'),
                       if (_timeLabels.containsKey(med.id))
                         Text(_timeLabels[med.id]!, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                     ],
                  ),
                );
              },
            ),
    );
  }
}
