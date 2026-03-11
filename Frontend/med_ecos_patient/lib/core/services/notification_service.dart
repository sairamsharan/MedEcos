import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/medicine_model.dart';
import '../models/meal_time_model.dart';
import 'preferences_service.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final PreferencesService _prefs = PreferencesService();

  Future<void> scheduleMedicineReminders(Medicine medicine) async {
    if (kIsWeb) return; // Notifications not heavily supported on web without excessive JS work

    int id = medicine.id.hashCode; // Simple ID generation

    for (var timing in medicine.timings) {
      // Calculate notification time via shared preferences utility
      var scheduledTime = await _prefs.calculateExactTime(timing);

      await _notificationsPlugin.zonedSchedule(
        id + timing.mealRef.index, // Unique ID per timing
        'Medicine Reminder',
        'Time to take ${medicine.name} (${medicine.dosage})',
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_channel',
            'Medicine Reminders',
            channelDescription: 'Reminders to take your medicine',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      );
    }
  }
  
  Future<void> cancelMedicineNotifications(String medicineId) async {
    final baseId = medicineId.hashCode;
    for (int i = 0; i < MealType.values.length; i++) {
      await _notificationsPlugin.cancel(baseId + i);
    }
  }
}
