import 'package:flutter/foundation.dart';
import '../models/medicine_model.dart';
import '../models/meal_time_model.dart';
import 'preferences_service.dart';

class NotificationService {
  final PreferencesService _prefs = PreferencesService();

  Future<void> scheduleMedicineReminders(Medicine medicine) async {
    int id = medicine.id.hashCode;

    for (var timing in medicine.timings) {
      var scheduledTime = await _prefs.calculateExactTime(timing);
      debugPrint("Notification Scheduled: Time to take ${medicine.name} at $scheduledTime");
      // In a full mobile deployment, flutter_local_notifications would be used here.
      // Web push notifications require external service workers.
    }
  }
  
  Future<void> cancelMedicineNotifications(String medicineId) async {
    debugPrint("Cancelled notifications for $medicineId");
  }
}
