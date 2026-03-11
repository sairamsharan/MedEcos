import 'package:flutter/material.dart';
import '../../../core/models/meal_time_model.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _prefs = PreferencesService();
  Map<String, MealTime> _mealTimes = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMealTimes();
  }

  Future<void> _loadMealTimes() async {
    final times = await _prefs.getAllMealTimes();
    setState(() {
      _mealTimes = times;
      _loading = false;
    });
  }

  Future<void> _updateMealTime(String key) async {
    final currentTime = _mealTimes[key]!;
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: currentTime.toTimeOfDay(),
    );

    if (newTime != null) {
      final newMealTime = MealTime(hour: newTime.hour, minute: newTime.minute);
      await _prefs.saveMealTime(key, newMealTime);
      setState(() {
        _mealTimes[key] = newMealTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Meal Times',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Set your daily meal times to receive timely medicine reminders.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                _buildTimeTile('Breakfast', PreferencesService.keyBreakfast),
                _buildTimeTile('Lunch', PreferencesService.keyLunch),
                _buildTimeTile('Snack', PreferencesService.keySnack),
                _buildTimeTile('Dinner', PreferencesService.keyDinner),
              ],
            ),
    );
  }

  Widget _buildTimeTile(String label, String key) {
    final time = _mealTimes[key];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(
          time?.toTimeOfDay().format(context) ?? '--:--',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: () => _updateMealTime(key),
      ),
    );
  }
}
