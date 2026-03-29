import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../services/payment_service.dart';
import '../../models/payment_model.dart';
import '../../models/unit_model.dart';
import '../../services/currency_formatter.dart';

class TenantDashboardScreen extends StatefulWidget {
  const TenantDashboardScreen({super.key});

  @override
  State<TenantDashboardScreen> createState() => _TenantDashboardScreenState();
}

class _TenantDashboardScreenState extends State<TenantDashboardScreen> {
  final DatabaseService _dbService = DatabaseService();
  final PaymentService _paymentService = PaymentService();

  UnitModel? _unit;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user?.assignedUnitId != null) {
      final unit = await _dbService.getUnit(user!.assignedUnitId!);
      if (mounted) {
        setState(() {
          _unit = unit;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome
            Text(
              'Welcome, ${user?.fullName.split(' ').first ?? 'Tenant'}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your rent and requests',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 24),

            // Rent Card
            if (_unit != null)
              Card(
                color: Colors.teal,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Monthly Rent',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Unit ${_unit!.unitNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _unit!.formattedRent,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Due on day ${_unit!.paymentDueDay ?? 1} of each month',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Payment Status
            Text(
              'Payment Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildPaymentStatus(user?.uid),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.payment,
                    title: 'Pay Rent',
                    color: Colors.green,
                    onTap: () {
                      // Navigate to payment screen
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.build,
                    title: 'Request Fix',
                    color: Colors.orange,
                    onTap: () {
                      // Navigate to maintenance screen
                    },
                  ),
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
            _buildRecentPayments(user?.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatus(String? tenantId) {
    if (tenantId == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No payment data'),
        ),
      );
    }

    return StreamBuilder<List<PaymentModel>>(
      stream: _paymentService.getPaymentsByTenant(tenantId),
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
        
        // Get current month payment
        final now = DateTime.now();
        final currentMonthPayment = payments.where((p) {
          return p.monthYear.contains(now.year.toString());
        }).toList();

        int paid = currentMonthPayment.where((p) => p.status == PaymentStatus.paid).length;
        int pending = currentMonthPayment.where((p) => p.status == PaymentStatus.pending).length;
        int overdue = currentMonthPayment.where((p) => p.status == PaymentStatus.overdue).length;

        return Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                'Paid',
                '$paid',
                Colors.green,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatusCard(
                'Pending',
                '$pending',
                Colors.orange,
                Icons.hourglass_empty,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatusCard(
                'Overdue',
                '$overdue',
                Colors.red,
                Icons.warning,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusCard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPayments(String? tenantId) {
    if (tenantId == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No payment history')),
        ),
      );
    }

    return StreamBuilder<List<PaymentModel>>(
      stream: _paymentService.getPaymentsByTenant(tenantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final payments = snapshot.data?.take(5).toList() ?? [];

        if (payments.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No payments yet',
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
                  backgroundColor: _getStatusColor(payment.status).withValues(alpha: 0.2),
                  child: Icon(
                    _getStatusIcon(payment.status),
                    color: _getStatusColor(payment.status),
                  ),
                ),
                title: Text(payment.formattedAmount),
                subtitle: Text(payment.monthYear),
                trailing: Chip(
                  label: Text(
                    payment.statusDisplay,
                    style: TextStyle(
                      color: _getStatusColor(payment.status),
                      fontSize: 11,
                    ),
                  ),
                  backgroundColor: _getStatusColor(payment.status).withValues(alpha: 0.1),
                  side: BorderSide.none,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.overdue:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Icons.check;
      case PaymentStatus.pending:
        return Icons.hourglass_empty;
      case PaymentStatus.overdue:
        return Icons.warning;
    }
  }
}