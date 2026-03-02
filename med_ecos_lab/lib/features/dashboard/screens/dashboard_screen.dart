import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/data_service.dart';
import '../widgets/sidebar.dart';
import '../widgets/header.dart';
import '../widgets/stat_card.dart';
import '../../requests/screens/test_requests_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

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
        return const TestRequestsScreen();
      case 2:
        return const Center(child: Text("Completed Reports Placeholder"));
      case 3:
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
                  "Lab Dashboard",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 24),
                // Stats Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final pendingCount =
                        DataService().pendingRequests.length.toString();
                    final completedCount =
                        DataService().completedReports.length.toString();

                    return Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: [
                        StatCard(
                            title: "Pending Tests",
                            value: pendingCount,
                            icon: Icons.science,
                            color: Colors.orange),
                        StatCard(
                            title: "Reports Ready",
                            value: completedCount,
                            icon: Icons.task_alt,
                            color: Colors.green),
                        StatCard(
                            title: "Samples Collected",
                            value: "18",
                            icon: Icons.bloodtype,
                            color: Colors.red),
                        StatCard(
                            title: "Urgent Requests",
                            value: "2",
                            icon: Icons.warning_amber,
                            color: Colors.redAccent),
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
                  child: Text("Lab Activity Chart Placeholder",
                      style: TextStyle(color: AppColors.textSecondary)),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          SizedBox(
            width: 250,
            child: Sidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: _onItemSelected,
            ),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }
}
