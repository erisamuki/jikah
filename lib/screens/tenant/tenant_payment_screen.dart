import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../services/payment_service.dart';
import '../../models/payment_model.dart';
import '../../models/unit_model.dart';
import '../../widgets/custom_text_field.dart';

class TenantPaymentScreen extends StatefulWidget {
  const TenantPaymentScreen({super.key});

  @override
  State<TenantPaymentScreen> createState() => _TenantPaymentScreenState();
}

class _TenantPaymentScreenState extends State<TenantPaymentScreen> {
  final DatabaseService _dbService = DatabaseService();
  final PaymentService _paymentService = PaymentService();

  UnitModel? _unit;
  PaymentModel? _pendingPayment;
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount to Pay
          Card(
            color: Colors.teal,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Amount Due',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _unit?.formattedRent ?? 'UGX 0',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getCurrentMonth(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Payment Methods
          Text(
            'Select Payment Method',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // MTN Mobile Money
          _buildPaymentMethodCard(
            title: 'MTN Mobile Money',
            subtitle: 'Pay using MTN MoMo',
            icon: Icons.phone_android,
            color: const Color(0xFFFFCC00), // MTN Yellow
            textColor: Colors.black,
            onTap: () => _showMTNPaymentDialog(context, user?.uid),
          ),
          const SizedBox(height: 12),

          // Airtel Money
          _buildPaymentMethodCard(
            title: 'Airtel Money',
            subtitle: 'Pay using Airtel Money',
            icon: Icons.phone_android,
            color: const Color(0xFFED1C24), // Airtel Red
            textColor: Colors.white,
            onTap: () => _showAirtelPaymentDialog(context, user?.uid),
          ),
          const SizedBox(height: 12),

          // Bank Card
          _buildPaymentMethodCard(
            title: 'Bank Card',
            subtitle: 'Visa / Mastercard',
            icon: Icons.credit_card,
            color: Colors.blue.shade700,
            textColor: Colors.white,
            onTap: () => _showBankCardDialog(context, user?.uid),
          ),
          const SizedBox(height: 24),

          // Payment Instructions
          Card(
            color: Colors.blue.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Payment Instructions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInstruction('1', 'Select your preferred payment method'),
                  _buildInstruction('2', 'Enter your phone number'),
                  _buildInstruction('3', 'You will receive a payment prompt'),
                  _buildInstruction('4', 'Enter your PIN to confirm'),
                  _buildInstruction('5', 'Receive instant confirmation'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: textColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.blue.shade700,
            child: Text(
              number,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentMonth() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }

  // ============ MTN MOMO PAYMENT ============
  void _showMTNPaymentDialog(BuildContext context, String? tenantId) {
    final phoneController = TextEditingController();
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC00),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.phone_android, color: Colors.black),
              ),
              const SizedBox(width: 12),
              const Text('MTN MoMo'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount: ${_unit?.formattedRent ?? "UGX 0"}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: phoneController,
                label: 'MTN Phone Number',
                hint: '0776XXXXXX',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC00).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You will receive a prompt on your phone. Enter your MTN MoMo PIN to complete payment.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      if (phoneController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter phone number'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() => isProcessing = true);

                      // Simulate payment processing
                      await Future.delayed(const Duration(seconds: 2));

                      // Create payment record
                      await _processPayment(
                        tenantId: tenantId!,
                        method: PaymentMethod.mtnMomo,
                        phoneNumber: phoneController.text.trim(),
                      );

                      setState(() => isProcessing = false);

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                        _showPaymentSuccessDialog(context);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCC00),
                foregroundColor: Colors.black,
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Pay Now'),
            ),
          ],
        ),
      ),
    );
  }

  // ============ AIRTEL MONEY PAYMENT ============
  void _showAirtelPaymentDialog(BuildContext context, String? tenantId) {
    final phoneController = TextEditingController();
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFED1C24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.phone_android, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text('Airtel Money'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount: ${_unit?.formattedRent ?? "UGX 0"}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: phoneController,
                label: 'Airtel Phone Number',
                hint: '0700XXXXXX',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFED1C24).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20, color: Color(0xFFED1C24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You will receive a prompt on your phone. Enter your Airtel Money PIN to complete payment.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      if (phoneController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter phone number'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() => isProcessing = true);

                      await Future.delayed(const Duration(seconds: 2));

                      await _processPayment(
                        tenantId: tenantId!,
                        method: PaymentMethod.airtelMoney,
                        phoneNumber: phoneController.text.trim(),
                      );

                      setState(() => isProcessing = false);

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                        _showPaymentSuccessDialog(context);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFED1C24),
                foregroundColor: Colors.white,
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Pay Now'),
            ),
          ],
        ),
      ),
    );
  }

  // ============ BANK CARD PAYMENT ============
  void _showBankCardDialog(BuildContext context, String? tenantId) {
    final cardNumberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.credit_card, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text('Bank Card'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount: ${_unit?.formattedRent ?? "UGX 0"}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: cardNumberController,
                  label: 'Card Number',
                  hint: '1234 5678 9012 3456',
                  prefixIcon: Icons.credit_card,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: expiryController,
                        label: 'Expiry',
                        hint: 'MM/YY',
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: cvvController,
                        label: 'CVV',
                        hint: '123',
                        keyboardType: TextInputType.number,
                        obscureText: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      setState(() => isProcessing = true);

                      await Future.delayed(const Duration(seconds: 2));

                      await _processPayment(
                        tenantId: tenantId!,
                        method: PaymentMethod.bankCard,
                      );

                      setState(() => isProcessing = false);

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                        _showPaymentSuccessDialog(context);
                      }
                    },
              child: isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Pay Now'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment({
    required String tenantId,
    required PaymentMethod method,
    String? phoneNumber,
  }) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || _unit == null) return;

    final payment = PaymentModel(
      id: '',
      tenantId: tenantId,
      landlordId: user.assignedLandlordId ?? '',
      propertyId: user.assignedPropertyId ?? '',
      unitId: user.assignedUnitId ?? '',
      amount: _unit!.rentAmount,
      status: PaymentStatus.paid,
      method: method,
      transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
      receiptNumber: 'RCP${DateTime.now().millisecondsSinceEpoch}',
      dueDate: DateTime.now(),
      paidDate: DateTime.now(),
      monthYear: _getCurrentMonth(),
      createdAt: DateTime.now(),
    );

    await _paymentService.createPayment(payment);
  }

  void _showPaymentSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.green,
              child: Icon(Icons.check, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your rent payment has been received.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _unit?.formattedRent ?? '',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate to receipt
            },
            child: const Text('View Receipt'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}