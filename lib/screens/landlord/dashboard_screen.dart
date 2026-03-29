import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../services/payment_service.dart';
import '../../services/maintenance_service.dart';
import '../../widgets/stat_card.dart';
import '../../models/payment_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _dbService = DatabaseService();
  final PaymentService _paymentService = PaymentService();
  final MaintenanceService _maintenanceService = MaintenanceService();

  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _paymentStats = {};
  int _pendingMaintenance = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    
    if (user == null) {
      setState(() {
        _isLoading = false;
        _error = 'User not found';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _dbService.getLandlordDashboardStats(user.uid);
      final paymentStats = await _paymentService.getPaymentStats(user.uid);
      final pendingMaintenance = await _maintenanceService.getPendingMaintenanceCount(user.uid);

      if (mounted) {
        setState(() {
          _stats = stats;
          _paymentStats = paymentStats;
          _pendingMaintenance = pendingMaintenance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Error loading dashboard', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Text(
              'Welcome back, ${user?.fullName.split(' ').first ?? 'Landlord'}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Here\'s your property overview',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 24),

            // Payment Status Cards
            Text(
              'Payment Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                final cardWidth = isWide
                    ? (constraints.maxWidth - 32) / 3
                    : constraints.maxWidth;
                
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: 'Paid',
                        value: '${_paymentStats['paid'] ?? 0}',
                        icon: Icons.check_circle,
                        iconColor: Colors.green,
                        backgroundColor: Colors.green.withValues(alpha: 0.1),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: 'Pending',
                        value: '${_paymentStats['pending'] ?? 0}',
                        icon: Icons.hourglass_empty,
                        iconColor: Colors.orange,
                        backgroundColor: Colors.orange.withValues(alpha: 0.1),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: 'Overdue',
                        value: '${_paymentStats['overdue'] ?? 0}',
                        icon: Icons.warning,
                        iconColor: Colors.red,
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Property Overview
            Text(
              'Property Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                final cardWidth = isWide
                    ? (constraints.maxWidth - 48) / 4
                    : (constraints.maxWidth - 16) / 2;
                
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: 'Properties',
                        value: '${_stats['totalProperties'] ?? 0}',
                        icon: Icons.apartment,
                        iconColor: Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: 'Total Units',
                        value: '${_stats['totalUnits'] ?? 0}',
                        icon: Icons.door_front_door,
                        iconColor: Colors.blue,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: 'Occupied',
                        value: '${_stats['occupiedUnits'] ?? 0}',
                        icon: Icons.people,
                        iconColor: Colors.green,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: 'Vacant',
                        value: '${_stats['vacantUnits'] ?? 0}',
                        icon: Icons.door_back_door,
                        iconColor: Colors.grey,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Quick Stats Row
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.manage_accounts,
                            size: 32,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_stats['totalManagers'] ?? 0}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Managers',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.people,
                            size: 32,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_stats['totalTenants'] ?? 0}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Tenants',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.build,
                            size: 32,
                            color: _pendingMaintenance > 0 ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_pendingMaintenance',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Pending Fixes',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Occupancy Rate
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Occupancy Rate',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (double.tryParse(_stats['occupancyRate']?.toString() ?? '0') ?? 0) / 100,
                              minHeight: 20,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${_stats['occupancyRate'] ?? 0}%',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recent Payments Section
            Text(
              'Recent Payments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildRecentPayments(user?.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPayments(String? userId) {
    if (userId == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No user found',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      );
    }

    return StreamBuilder<List<PaymentModel>>(
      stream: _paymentService.getRecentPayments(userId, limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Error loading payments',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),
          );
        }

        final payments = snapshot.data ?? [];

        if (payments.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No recent payments',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final payment = payments[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withValues(alpha: 0.2),
                  child: const Icon(Icons.check, color: Colors.green),
                ),
                title: Text(payment.formattedAmount),
                subtitle: Text(payment.monthYear),
                trailing: Text(
                  payment.methodDisplay,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              );
            },
          ),
        );
      },
    );
  }
}