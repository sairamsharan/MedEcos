import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/login_screen.dart';

class Sidebar extends StatelessWidget {
  final Function(int) onItemSelected;
  final int selectedIndex;
  final String userRole;
  final String userName;

  const Sidebar({
    super.key, 
    required this.onItemSelected, 
    required this.selectedIndex,
    required this.userRole,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> items = [];
    
    if (userRole == 'Patient') {
      items = [
        _NavItem(icon: Icons.dashboard, label: "Dashboard", isSelected: selectedIndex == 0, onTap: () => onItemSelected(0)),
        _NavItem(icon: Icons.receipt_long, label: "Prescriptions", isSelected: selectedIndex == 1, onTap: () => onItemSelected(1)),
        _NavItem(icon: Icons.calendar_today, label: "Appointments", isSelected: selectedIndex == 2, onTap: () => onItemSelected(2)),
        _NavItem(icon: Icons.history, label: "History", isSelected: selectedIndex == 3, onTap: () => onItemSelected(3)),
        _NavItem(icon: Icons.science, label: "Lab Orders", isSelected: selectedIndex == 4, onTap: () => onItemSelected(4)),
        const Spacer(),
      ];
    } else if (userRole == 'Doctor') {
      items = [
        _NavItem(icon: Icons.dashboard, label: "Dashboard", isSelected: selectedIndex == 0, onTap: () => onItemSelected(0)),
        _NavItem(icon: Icons.assignment, label: "Prescriptions", isSelected: selectedIndex == 1, onTap: () => onItemSelected(1)),
        _NavItem(icon: Icons.people, label: "Patients", isSelected: selectedIndex == 2, onTap: () => onItemSelected(2)),
        _NavItem(icon: Icons.calendar_month, label: "Appointments", isSelected: selectedIndex == 3, onTap: () => onItemSelected(3)),
        const Spacer(),
      ];
    } else if (userRole == 'Pharmacist') {
      items = [
        _NavItem(icon: Icons.dashboard, label: "Dashboard", isSelected: selectedIndex == 0, onTap: () => onItemSelected(0)),
        _NavItem(icon: Icons.receipt, label: "Prescriptions", isSelected: selectedIndex == 1, onTap: () => onItemSelected(1)),
        _NavItem(icon: Icons.search, label: "Lookup", isSelected: selectedIndex == 2, onTap: () => onItemSelected(2)),
        _NavItem(icon: Icons.inventory, label: "Inventory", isSelected: selectedIndex == 3, onTap: () => onItemSelected(3)),
        _NavItem(icon: Icons.point_of_sale, label: "Billing", isSelected: selectedIndex == 4, onTap: () => onItemSelected(4)),
        const Spacer(),
      ];
    } else if (userRole == 'Pathologist') {
      items = [
        _NavItem(icon: Icons.dashboard, label: "Dashboard", isSelected: selectedIndex == 0, onTap: () => onItemSelected(0)),
        _NavItem(icon: Icons.search, label: "Lookup", isSelected: selectedIndex == 1, onTap: () => onItemSelected(1)),
        _NavItem(icon: Icons.science, label: "Lab Tests", isSelected: selectedIndex == 2, onTap: () => onItemSelected(2)),
        const Spacer(),
      ];
    }

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo Area
          Image.asset("assets/Icon.jpeg", height: 80, width: 80),
          const SizedBox(height: 16),
          Text(
            "MedEcos",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: 48),
          
          ...items,
          
          Builder(
            builder: (context) {
              int profileIndex = 0;
              if (userRole == 'Patient') profileIndex = 5;
              else if (userRole == 'Doctor') profileIndex = 4;
              else if (userRole == 'Pharmacist') profileIndex = 5;
              else if (userRole == 'Pathologist') profileIndex = 3;
              
              final isProfileSelected = selectedIndex == profileIndex;

              return InkWell(
                onTap: () => onItemSelected(profileIndex),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isProfileSelected ? AppColors.surfaceVariant : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isProfileSelected ? AppColors.primary.withOpacity(0.5) : Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(Icons.person, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 14,
                                color: isProfileSelected ? AppColors.primary : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              userRole,
                              style: TextStyle(
                                color: isProfileSelected ? AppColors.primary.withOpacity(0.7) : AppColors.textSecondary, 
                                fontSize: 12
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          ),
          const SizedBox(height: 10),
          _NavItem(
            icon: Icons.logout, 
            label: "Logout", 
            isSelected: false,
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.surfaceVariant : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
      ),
    );
  }
}
