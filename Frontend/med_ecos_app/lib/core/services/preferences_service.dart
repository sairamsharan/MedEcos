import 'package:shared_preferences/shared_preferences.dart';
import 'package:med_ecos_patient/core/models/meal_time_model.dart';
import 'package:med_ecos_patient/core/models/medicine_model.dart';

class PreferencesService {
  static const String keyBreakfast = 'meal_breakfast';
  static const String keyLunch = 'meal_lunch';
  static const String keySnack = 'meal_snack';
  static const String keyDinner = 'meal_dinner';

  Future<void> saveMealTime(String key, MealTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, time.toStringFormat());
  }

  Future<MealTime> getMealTime(String key, MealTime defaultTime) async {
    final prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString(key);
    if (stored != null) {
      return MealTime.fromString(stored);
    }
    return defaultTime;
  }

  Future<Map<String, MealTime>> getAllMealTimes() async {
    return {
      keyBreakfast: await getMealTime(keyBreakfast, MealTime(hour: 8, minute: 0)),
      keyLunch: await getMealTime(keyLunch, MealTime(hour: 13, minute: 0)),
      keySnack: await getMealTime(keySnack, MealTime(hour: 17, minute: 0)),
      keyDinner: await getMealTime(keyDinner, MealTime(hour: 20, minute: 0)),
    };
  }

  Future<DateTime> calculateExactTime(MedicineTiming timing) async {
    final mealTimes = await getAllMealTimes();
    MealTime mealTime;
    switch (timing.mealRef) {
      case MealType.breakfast:
        mealTime = mealTimes[keyBreakfast]!;
        break;
      case MealType.lunch:
        mealTime = mealTimes[keyLunch]!;
        break;
      case MealType.snack:
        mealTime = mealTimes[keySnack]!;
        break;
      case MealType.dinner:
        mealTime = mealTimes[keyDinner]!;
        break;
    }

    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      mealTime.hour,
      mealTime.minute,
    ).add(Duration(minutes: timing.offsetMinutes));

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    return scheduledTime;
  }
}
