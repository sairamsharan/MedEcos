import 'package:flutter/material.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/preferences_service.dart';
import '../widgets/add_medicine_dialog.dart';

class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  final DatabaseService _db = DatabaseService();
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
      final list = await _db.getMedicines();
      Map<String, String> labels = {};
      
      for (var med in list) {
        if (med.timings.isNotEmpty) {
           List<String> timeStrings = [];
           for (var t in med.timings) {
             final time = await _prefs.calculateExactTime(t);
             final timeStr = DateFormat('h:mm a').format(time);
             final typeName = t.timeType.name.replaceAll(RegExp(r'(?=[A-Z])'), ' ');
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

  void _addMedicine() async {
    await showDialog(
      context: context,
      builder: (context) => const AddMedicineDialog(),
    );
    _loadMedicines();
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
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _db.deleteMedicine(med.id);
                      await NotificationService().cancelMedicineNotifications(med.id);
                      _loadMedicines();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMedicine,
        child: const Icon(Icons.add),
      ),
    );
  }
}
