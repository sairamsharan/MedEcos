import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';

void main() {
  runApp(const MedEcosPharmacistApp());
}

class MedEcosPharmacistApp extends StatelessWidget {
  const MedEcosPharmacistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedEcos Pharmacist',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DashboardScreen(),
    );
  }
}
