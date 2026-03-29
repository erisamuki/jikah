import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/theme_service.dart';
import '../../services/database_service.dart';
import '../../models/property_model.dart';
import '../auth/login_screen.dart';
import 'manager_dashboard_screen.dart';
import 'manager_tenants_screen.dart';
import 'manager_maintenance_screen.dart';
import 'manager_contacts_screen.dart';
import 'manager_profile_screen.dart';
import 'manager_settings_screen.dart';

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  int _selectedIndex = 0;
  final DatabaseService _dbService = DatabaseService();
  PropertyModel? _assignedProperty;

  final List<Widget> _screens = [
    const ManagerDashboardScreen(),
    const ManagerTenantsScreen(),
    const ManagerMaintenanceScreen(),
    const ManagerContactsScreen(),
    const ManagerProfileScreen(),
    const ManagerSettingsScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Tenants',
    'Maintenance',
    'Contacts',
    'Profile',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    _loadAssignedProperty();
  }

  Future<void> _loadAssignedProperty() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null && user.assignedPropertyId != null) {
      final property = await _dbService.getProperty(user.assignedPropertyId!);
      if (mounted) {
        setState(() {
          _assignedProperty = property;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeService = context.watch<ThemeService>();
    final user = authProvider.currentUser;
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        leading: isWideScreen
            ? null
            : Builder(
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
          if (isWideScreen)
            Container(
              width: 250,
              color: Theme.of(context).cardColor,
              child: _buildSidebarContent(user, authProvider),
            ),
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
          color: Colors.blue.shade700,
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
                          user?.fullName.substring(0, 1).toUpperCase() ?? 'M',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? 'Manager',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _assignedProperty?.name ?? 'Property Manager',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                if (_assignedProperty != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _assignedProperty!.location,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
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
              _buildMenuItem(Icons.people, 'Tenants', 1),
              _buildMenuItem(Icons.build, 'Maintenance', 2),
              _buildMenuItem(Icons.contacts, 'Contacts', 3),
              const Divider(),
              _buildMenuItem(Icons.person, 'Profile', 4),
              _buildMenuItem(Icons.settings, 'Settings', 5),
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
            'Jikah Manager v1.0.0',
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
        color: isSelected ? Colors.blue.shade700 : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue.shade700 : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue.withValues(alpha: 0.1),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (MediaQuery.of(context).size.width <= 800) {
          Navigator.pop(context);
        }
      },
    );
  }
}