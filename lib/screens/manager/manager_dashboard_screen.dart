import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../services/payment_service.dart';
import '../../services/maintenance_service.dart';
import '../../models/payment_model.dart';
import '../../models/user_model.dart';
import '../../widgets/stat_card.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  final DatabaseService _dbService = DatabaseService();
  final PaymentService _paymentService = PaymentService();
  final MaintenanceService _maintenanceService = MaintenanceService();

  Map<String, dynamic> _paymentStats = {};
  final int _totalTenants = 0;
  int _pendingMaintenance = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || user.assignedLandlordId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get payment stats from landlord's data
      final paymentStats = await _paymentService.getPaymentStats(user.assignedLandlordId!);
      
      // Get pending maintenance for the property
      int pendingMaintenance = 0;
      if (user.assignedPropertyId != null) {
        pendingMaintenance = await _maintenanceService.getPendingMaintenanceCount(user.assignedLandlordId!);
      }

      if (mounted) {
        setState(() {
          _paymentStats = paymentStats;
          _pendingMaintenance = pendingMaintenance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
              'Welcome, ${user?.fullName.split(' ').first ?? 'Manager'}!',
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
              'Tenant Payment Status',
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

            // Quick Stats
            Row(
              children: [
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
                            'Pending Maintenance',
                            style: TextStyle(color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTenantCountCard(user),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Payments
            Text(
              'Recent Payments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildRecentPayments(user?.assignedLandlordId),
          ],
        ),
      ),
    );
  }

  Widget _buildTenantCountCard(UserModel? user) {
    if (user?.assignedPropertyId == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.people, size: 32, color: Colors.blue.shade700),
              const SizedBox(height: 8),
              Text(
                '0',
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
      );
    }

    return StreamBuilder<List<UserModel>>(
      stream: _dbService.getTenantsByProperty(user!.assignedPropertyId!),
      builder: (context, snapshot) {
        final tenantCount = snapshot.data?.length ?? 0;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.people, size: 32, color: Colors.blue.shade700),
                const SizedBox(height: 8),
                Text(
                  '$tenantCount',
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
        );
      },
    );
  }

  Widget _buildRecentPayments(String? landlordId) {
    if (landlordId == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No data available',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      );
    }

    return StreamBuilder<List<PaymentModel>>(
      stream: _paymentService.getRecentPayments(landlordId, limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
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
                    Icon(Icons.payments_outlined, size: 48, color: Colors.grey.shade400),
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