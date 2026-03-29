import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/theme_service.dart';
import '../auth/login_screen.dart';
import 'dashboard_screen.dart';
import 'properties_screen.dart';
import 'tenants_screen.dart';
import 'managers_screen.dart';
import 'maintenance_screen.dart';
// ADD THIS
import 'reports_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class LandlordHomeScreen extends StatefulWidget {
  const LandlordHomeScreen({super.key});

  @override
  State<LandlordHomeScreen> createState() => _LandlordHomeScreenState();
}

class _LandlordHomeScreenState extends State<LandlordHomeScreen> {
  int _selectedIndex = 0;
  // NEW:
final List<Widget> _screens = [
  const DashboardScreen(),
  const PropertiesScreen(),
  const TenantsScreen(),
  const ManagersScreen(),
  const MaintenanceScreen(),
  //const SmsScreen(), // ADD THIS
  const ReportsScreen(),
  const ProfileScreen(),
  const SettingsScreen(),
];

final List<String> _titles = [
  'Dashboard',
  'Properties',
  'Tenants',
  'Managers',
  'Maintenance',
  'SMS Reminders', // ADD THIS
  'Reports',
  'Profile',
  'Settings',
];
  
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeService = context.watch<ThemeService>();
    final user = authProvider.currentUser;
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        leading: isWideScreen ? null : Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () => themeService.toggleTheme(),
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      drawer: isWideScreen ? null : _buildDrawer(user, authProvider),
      body: Row(
        children: [
          // Sidebar for wide screens
          if (isWideScreen)
            Container(
              width: 250,
              color: Theme.of(context).cardColor,
              child: _buildSidebarContent(user, authProvider),
            ),
          // Main content
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(dynamic user, AuthProvider authProvider) {
    return Drawer(
      child: _buildSidebarContent(user, authProvider),
    );
  }

  Widget _buildSidebarContent(dynamic user, AuthProvider authProvider) {
    return Column(
      children: [
        // User header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: Theme.of(context).primaryColor,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: user?.profileImageUrl != null
                      ? NetworkImage(user!.profileImageUrl!)
                      : null,
                  child: user?.profileImageUrl == null
                      ? Text(
                          user?.fullName.substring(0, 1).toUpperCase() ?? 'L',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? 'Landlord',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.phone ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Menu items
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildMenuItem(Icons.dashboard, 'Dashboard', 0),
              _buildMenuItem(Icons.apartment, 'Properties', 1),
              _buildMenuItem(Icons.people, 'Tenants', 2),
              _buildMenuItem(Icons.manage_accounts, 'Managers', 3),
              _buildMenuItem(Icons.build, 'Maintenance', 4),
              _buildMenuItem(Icons.bar_chart, 'Reports', 5),
              const Divider(),
              _buildMenuItem(Icons.person, 'Profile', 6),
              _buildMenuItem(Icons.settings, 'Settings', 7),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await authProvider.logout();
                  if (!mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        // App version
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Jikah v1.0.0',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        // Close drawer on mobile
        if (MediaQuery.of(context).size.width <= 800) {
          Navigator.pop(context);
        }
      },
    );
  }
}