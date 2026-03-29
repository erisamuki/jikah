import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/theme_service.dart';
import '../../services/database_service.dart';
import '../../models/property_model.dart';
import '../../models/unit_model.dart';
import '../auth/login_screen.dart';
import 'tenant_dashboard_screen.dart';
import 'tenant_payment_screen.dart';
import 'tenant_maintenance_screen.dart';
import 'tenant_history_screen.dart';
import 'tenant_profile_screen.dart';
import 'tenant_settings_screen.dart';

class TenantHomeScreen extends StatefulWidget {
  const TenantHomeScreen({super.key});

  @override
  State<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {
  int _selectedIndex = 0;
  final DatabaseService _dbService = DatabaseService();
  PropertyModel? _property;
  UnitModel? _unit;

  final List<Widget> _screens = [
    const TenantDashboardScreen(),
    const TenantPaymentScreen(),
    const TenantMaintenanceScreen(),
    const TenantHistoryScreen(),
    const TenantProfileScreen(),
    const TenantSettingsScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Make Payment',
    'Maintenance',
    'Payment History',
    'Profile',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    _loadPropertyAndUnit();
  }

  Future<void> _loadPropertyAndUnit() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      if (user.assignedPropertyId != null) {
        final property = await _dbService.getProperty(user.assignedPropertyId!);
        if (mounted) setState(() => _property = property);
      }
      if (user.assignedUnitId != null) {
        final unit = await _dbService.getUnit(user.assignedUnitId!);
        if (mounted) setState(() => _unit = unit);
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
        backgroundColor: Colors.teal,
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
          color: Colors.teal,
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
                          user?.fullName.substring(0, 1).toUpperCase() ?? 'T',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? 'Tenant',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_property != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _property!.name,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
                if (_unit != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Unit ${_unit!.unitNumber}',
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
              _buildMenuItem(Icons.payment, 'Make Payment', 1),
              _buildMenuItem(Icons.build, 'Maintenance', 2),
              _buildMenuItem(Icons.history, 'Payment History', 3),
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
            'Jikah Tenant v1.0.0',
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
        color: isSelected ? Colors.teal : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.teal : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.teal.withValues(alpha: 0.1),
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