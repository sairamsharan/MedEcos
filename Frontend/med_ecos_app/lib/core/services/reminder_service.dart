import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';
import '../utils/medicine_utils.dart';

class MedicineDose {
  final String medicineId; // Could be prescription ID + medicine Name
  final String medicineName;
  final String timingLabel; // e.g. "Morning", "Evening"
  final DateTime expectedTime;
  final String context; // e.g. "Before Food"
  final String instruction;
  String status; // "PENDING", "TAKEN", "SKIPPED"

  MedicineDose({
    required this.medicineId,
    required this.medicineName,
    required this.timingLabel,
    required this.expectedTime,
    required this.context,
    required this.instruction,
    this.status = 'PENDING',
  });
}

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  Future<Map<String, dynamic>> _getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final res = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/api/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return {};
  }

  DateTime _parseTimeWithOffset(String timeString, String contextStr) {
    // timeString e.g. "08:00 AM"
    final now = DateTime.now();
    try {
      final format = DateFormat("hh:mm a");
      final parsedTime = format.parse(timeString);
      
      var expectedTime = DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
      
      // Apply offset
      final cLower = contextStr.toLowerCase();
      if (cLower.contains('before')) {
        expectedTime = expectedTime.subtract(const Duration(minutes: 30));
      } else if (cLower.contains('after')) {
        expectedTime = expectedTime.add(const Duration(minutes: 30));
      }
      return expectedTime;
    } catch (e) {
      return now;
    }
  }

  Future<List<MedicineDose>> getTodaysReminders() async {
    final profile = await _getProfile();
    final routine = profile['routine'] ?? {};
    
    final morningTime = routine['morning']?.toString() ?? '08:00 AM';
    final afternoonTime = routine['afternoon']?.toString() ?? '01:00 PM';
    final eveningTime = routine['evening']?.toString() ?? '05:00 PM';
    final nightTime = routine['night']?.toString() ?? '09:00 PM';

    final api = ApiService();
    await api.loadData();
    final prescriptions = api.prescriptions;

    List<MedicineDose> todayDoses = [];

    for (var p in prescriptions) {
      for (var med in p.medicines) {
        final name = med['name'] ?? 'Unknown';
        final duration = med['duration'] ?? '';
        final timing = med['timing'] ?? ''; // e.g. "Morning, Evening"
        final ctx = med['context'] ?? '';
        final inst = med['instruction'] ?? '';

        if (MedicineUtils.isActiveMedicine(p.date, duration)) {
          var timingsList = timing.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          
          if (timingsList.isEmpty) {
            // Fallback for older prescriptions lacking explicit 'timing' fields
            final dosageStr = (med['frequency']?.isNotEmpty == true) ? med['frequency']! : (med['dosage'] ?? '');
            final parts = dosageStr.split('-');
            if (parts.isNotEmpty) {
              if (parts[0].trim() != '0' && parts[0].trim().isNotEmpty) timingsList.add('Morning');
              if (parts.length >= 2 && parts[1].trim() != '0' && parts[1].trim().isNotEmpty) timingsList.add('Afternoon');
              if (parts.length >= 3 && parts[2].trim() != '0' && parts[2].trim().isNotEmpty) timingsList.add('Evening');
              if (parts.length >= 4 && parts[3].trim() != '0' && parts[3].trim().isNotEmpty) timingsList.add('Night');
            } else {
              // Default to Morning if unparseable
              timingsList.add('Morning');
            }
          }
          
          for (var t in timingsList) {
            String baseTimeStr = morningTime;
            if (t.toLowerCase() == 'afternoon') baseTimeStr = afternoonTime;
            if (t.toLowerCase() == 'evening') baseTimeStr = eveningTime;
            if (t.toLowerCase() == 'night') baseTimeStr = nightTime;

            final expectedTime = _parseTimeWithOffset(baseTimeStr, ctx);
            
            todayDoses.add(MedicineDose(
              medicineId: "${p.id}_$name",
              medicineName: name,
              timingLabel: t,
              expectedTime: expectedTime,
              context: ctx,
              instruction: inst,
            ));
          }
        }
      }
    }

    // Now cross-reference with today's history
    final history = await api.getMedicineHistory();
    
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    // History contains { medicineName, takenTime, status }
    for (var dose in todayDoses) {
      // Find history log for this medicine today that roughly matches the timing
      // To simplify, if there's a log for this medicine today, we might just match it.
      // But a medicine can be taken twice a day. So we check if there's a log within +/- 4 hours of expected time.
      bool foundLog = false;
      for (var h in history) {
        if (h['medicineName'] == dose.medicineName) {
          final logTime = DateTime.parse(h['takenTime']).toLocal();
          if (logTime.year == todayStart.year && logTime.month == todayStart.month && logTime.day == todayStart.day) {
            final diff = logTime.difference(dose.expectedTime).inHours.abs();
            if (diff <= 4) {
               dose.status = h['status'] ?? 'TAKEN';
               foundLog = true;
               break;
            }
          }
        }
      }

      if (!foundLog) {
        // If no log and time has passed (give a 1 hour grace period), it's missed
        if (now.isAfter(dose.expectedTime.add(const Duration(hours: 1)))) {
          dose.status = 'MISSED'; // Not explicitly skipped by user, but missed
        }
      }
    }

    // Sort: MISSED first, PENDING next, TAKEN/SKIPPED last. And by time.
    todayDoses.sort((a, b) {
       final statusWeightA = _getStatusWeight(a.status);
       final statusWeightB = _getStatusWeight(b.status);
       if (statusWeightA != statusWeightB) {
         return statusWeightA.compareTo(statusWeightB);
       }
       return a.expectedTime.compareTo(b.expectedTime);
    });

    return todayDoses;
  }

  int _getStatusWeight(String status) {
    switch (status) {
      case 'MISSED': return 0;
      case 'PENDING': return 1;
      default: return 2; // TAKEN, SKIPPED
    }
  }

  Future<void> logDose(MedicineDose dose, String status) async {
    await ApiService().logMedicineHistory(dose.medicineId, dose.medicineName, dose.expectedTime, status);
  }
}
