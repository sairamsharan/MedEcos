import 'package:flutter/material.dart';

class MealTime {
  final int hour;
  final int minute;

  MealTime({required this.hour, required this.minute});
  
  TimeOfDay toTimeOfDay() => TimeOfDay(hour: hour, minute: minute);
  
  String toStringFormat() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  factory MealTime.fromString(String time) {
    final parts = time.split(':');
    return MealTime(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
