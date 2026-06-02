import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/sidebar.dart';
import 'widgets/header.dart';
import 'widgets/stat_card.dart';
import '../prescription/screens/prescription_list_screen.dart';
import '../patient/screens/patient_lookup_screen.dart';
import 'screens/inventory_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  
  int _prescriptionsToday = 0;
  int _pendingOrders = 0;
  int _totalCustomers = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('pharmacist_jwt_token') ?? '';
      
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/v1/pharmacist/dashboard-stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _prescriptionsToday = data['prescriptionsToday'] ?? 0;
            _pendingOrders = data['pendingOrders'] ?? 0;
            _totalCustomers = data['totalCustomers'] ?? 0;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Failed to fetch stats: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardOverview();
      case 1:
        return const PrescriptionListScreen();
      case 2:
        return const PatientLookupScreen();
      case 3:
        return const InventoryScreen();
      case 4:
        return const Center(child: Text("Settings Placeholder"));
      default:
        return const Center(child: Text("Coming Soon"));
    }
  }

  Widget _buildDashboardOverview() {
    return Column(
      children: [
        const Header(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dashboard",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 24),
                // Stats Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: [
                        StatCard(title: "Prescriptions Today", value: _prescriptionsToday.toString(), icon: Icons.receipt_long, color: Colors.blue),
                        StatCard(title: "Pending Orders", value: _pendingOrders.toString(), icon: Icons.shopping_basket, color: Colors.orange),
                        StatCard(title: "Total Customers", value: _totalCustomers.toString(), icon: Icons.people, color: Colors.teal),
                        StatCard(title: "Weekly Engagement", value: "+12%", icon: Icons.trending_up, color: Colors.green),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                // Placeholder for Chart or other content
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text("Engagement Chart Placeholder", style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          SizedBox(
            width: 250, 
            child: Sidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: _onItemSelected,
            ),
          ),
          // Main Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }
}
