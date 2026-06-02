import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Failed to load .env file: $e");
  }
  
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('doctor_jwt_token');

  runApp(MedEcosDoctorApp(initialToken: token));
}

class MedEcosDoctorApp extends StatelessWidget {
  final String? initialToken;
  
  const MedEcosDoctorApp({super.key, this.initialToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedEcos Doctor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: initialToken != null ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
