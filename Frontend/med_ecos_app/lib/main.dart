import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  runApp(MyApp(initialToken: token));
}

class MyApp extends StatelessWidget {
  final String? initialToken;
  
  const MyApp({super.key, this.initialToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedEcos App',
      theme: AppTheme.lightTheme,
      home: initialToken != null && initialToken!.isNotEmpty ? const DashboardScreen() : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
