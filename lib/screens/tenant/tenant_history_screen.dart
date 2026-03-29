import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/payment_service.dart';
import '../../models/payment_model.dart';
import '../../widgets/empty_state.dart';

class TenantHistoryScreen extends StatefulWidget {
  const TenantHistoryScreen({super.key});

  @override
  State<TenantHistoryScreen> createState() => _TenantHistoryScreenState();
}

class _TenantHistoryScreenState extends State<TenantHistoryScreen> {
  final PaymentService _paymentService = PaymentService();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<List<PaymentModel>>(
      stream: _paymentService.getPaymentsByTenant(user.uid),
      builder: (context, snapshot) {
        print('=== Payment History Debug ===');
    print('Connection state: ${snapshot.connectionState}');
    print('Has error: ${snapshot.hasError}');
    print('Error: ${snapshot.error}');
    print('Has data: ${snapshot.hasData}');
    print('Data length: ${snapshot.data?.length ?? 0}');
    print('Tenant ID: ${user.uid}');
    print('=============================');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final payments = snapshot.data ?? [];

        if (payments.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long,
            title: 'No Payment History',
            subtitle: 'Your payment records will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return _buildPaymentCard(payment, user.fullName);
          },
        );
      },
    );
  }

  Widget _buildPaymentCard(PaymentModel payment, String tenantName) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: payment.status == PaymentStatus.paid
            ? () => _showReceiptDialog(context, payment, tenantName)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    payment.monthYear,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildStatusChip(payment.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    payment.formattedAmount,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(payment.status),
                    ),
                  ),
                  if (payment.status == PaymentStatus.paid)
                    TextButton.icon(
                      onPressed: () => _showReceiptDialog(context, payment, tenantName),
                      icon: const Icon(Icons.receipt, size: 18),
                      label: const Text('Receipt'),
                    ),
                ],
              ),
              if (payment.status == PaymentStatus.paid) ...[
                const Divider(),
                Row(
                  children: [
                    _buildDetailItem(
                      Icons.calendar_today,
                      'Paid on',
                      _formatDate(payment.paidDate!),
                    ),
                    const SizedBox(width: 24),
                    _buildDetailItem(
                      Icons.payment,
                      'Method',
                      payment.methodDisplay,
                    ),
                  ],
                ),
                if (payment.transactionId != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailItem(
                    Icons.tag,
                    'Transaction ID',
                    payment.transactionId!,
                  ),
                ],
              ],
              if (payment.status == PaymentStatus.pending ||
                  payment.status == PaymentStatus.overdue) ...[
                const Divider(),
                Row(
                  children: [
                    _buildDetailItem(
                      Icons.event,
                      'Due date',
                      _formatDate(payment.dueDate),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStatusChip(PaymentStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case PaymentStatus.paid:
        color = Colors.green;
        text = 'Paid';
        icon = Icons.check_circle;
        break;
      case PaymentStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        icon = Icons.hourglass_empty;
        break;
      case PaymentStatus.overdue:
        color = Colors.red;
        text = 'Overdue';
        icon = Icons.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ============ RECEIPT DIALOG ============
  void _showReceiptDialog(BuildContext context, PaymentModel payment, String tenantName) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Receipt Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'PAYMENT RECEIPT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jikah Rental Management',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Receipt Body
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Receipt Number
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Receipt #${payment.receiptNumber ?? "N/A"}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Amount
                    Text(
                      payment.formattedAmount,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      payment.monthYear,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Details
                    const Divider(),
                    _buildReceiptRow('Tenant', tenantName),
                    _buildReceiptRow('Payment Date', _formatDate(payment.paidDate!)),
                    _buildReceiptRow('Payment Method', payment.methodDisplay),
                    if (payment.transactionId != null)
                      _buildReceiptRow('Transaction ID', payment.transactionId!),
                    _buildReceiptRow('Status', 'PAID', valueColor: Colors.green),
                    const Divider(),

                    const SizedBox(height: 16),

                    // Verified Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Colors.green, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Payment Verified',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Receipt download coming soon!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}