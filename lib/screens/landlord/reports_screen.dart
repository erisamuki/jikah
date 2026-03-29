import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/payment_service.dart';
import '../../services/expense_service.dart';
import '../../services/currency_formatter.dart';
import '../../models/expense_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final PaymentService _paymentService = PaymentService();
  final ExpenseService _expenseService = ExpenseService();
  late TabController _tabController;

  Map<String, dynamic> _paymentStats = {};
  double _totalExpenses = 0;
  Map<String, double> _expensesByCategory = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final paymentStats = await _paymentService.getPaymentStats(user.uid);
      final totalExpenses = await _expenseService.getTotalExpenses(user.uid);
      final expensesByCategory =
          await _expenseService.getExpensesByCategory(user.uid);

      if (mounted) {
        setState(() {
          _paymentStats = paymentStats;
          _totalExpenses = totalExpenses;
          _expensesByCategory = expensesByCategory;
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

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Income'),
            Tab(text: 'Expenses'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildIncomeTab(),
              _buildExpensesTab(user?.uid ?? ''),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeTab() {
    final totalCollected = _paymentStats['totalCollected'] ?? 0.0;
    final totalPending = _paymentStats['totalPending'] ?? 0.0;
    final totalIncome = totalCollected + totalPending;

    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Collected',
                    CurrencyFormatter.formatUGX(totalCollected),
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Pending',
                    CurrencyFormatter.formatUGX(totalPending),
                    Colors.orange,
                    Icons.hourglass_empty,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryCard(
              'Expected Total',
              CurrencyFormatter.formatUGX(totalIncome),
              Theme.of(context).primaryColor,
              Icons.account_balance_wallet,
            ),
            const SizedBox(height: 24),

            // Payment Breakdown
            Text(
              'Payment Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildBreakdownRow(
                      'Paid Tenants',
                      '${_paymentStats['paid'] ?? 0}',
                      Colors.green,
                    ),
                    const Divider(),
                    _buildBreakdownRow(
                      'Pending Payments',
                      '${_paymentStats['pending'] ?? 0}',
                      Colors.orange,
                    ),
                    const Divider(),
                    _buildBreakdownRow(
                      'Overdue Payments',
                      '${_paymentStats['overdue'] ?? 0}',
                      Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Net Income
            Text(
              'Net Income',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Income - Expenses',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatUGX(totalCollected - _totalExpenses),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesTab(String landlordId) {
    return Column(
      children: [
        // Summary
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Expenses',
                  CurrencyFormatter.formatUGX(_totalExpenses),
                  Colors.red,
                  Icons.trending_down,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddExpenseDialog(context, landlordId),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ),

        // Expenses by Category
        if (_expensesByCategory.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'By Category',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: _expensesByCategory.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _getCategoryName(entry.key),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                CurrencyFormatter.formatUGX(entry.value),
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Recent Expenses List
        Expanded(
          child: StreamBuilder<List<ExpenseModel>>(
            stream: _expenseService.getExpensesByLandlord(landlordId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final expenses = snapshot.data ?? [];

              if (expenses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No expenses recorded',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                        child: const Icon(Icons.receipt, color: Colors.red),
                      ),
                      title: Text(expense.title),
                      subtitle: Text(expense.categoryDisplay),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            expense.formattedAmount,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            '${expense.date.day}/${expense.date.month}/${expense.date.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(label),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'maintenance':
        return 'Maintenance';
      case 'utilities':
        return 'Utilities';
      case 'taxes':
        return 'Taxes';
      case 'insurance':
        return 'Insurance';
      case 'management':
        return 'Management';
      default:
        return 'Other';
    }
  }

  void _showAddExpenseDialog(BuildContext context, String landlordId) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    ExpenseCategory selectedCategory = ExpenseCategory.maintenance;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Expense'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: titleController,
                    label: 'Title',
                    hint: 'e.g., Plumbing repair',
                    prefixIcon: Icons.title,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: amountController,
                    label: 'Amount (UGX)',
                    hint: 'e.g., 150000',
                    prefixIcon: Icons.money,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Required';
                      if (double.tryParse(v!) == null) return 'Invalid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ExpenseCategory>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: ExpenseCategory.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(_getCategoryName(cat.name)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedCategory = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    ),
                    subtitle: const Text('Tap to change date'),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: descriptionController,
                    label: 'Description (Optional)',
                    prefixIcon: Icons.description,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CustomButton(
              text: 'Add Expense',
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final expense = ExpenseModel(
                    id: '',
                    landlordId: landlordId,
                    title: titleController.text.trim(),
                    amount: double.parse(amountController.text.trim()),
                    category: selectedCategory,
                    date: selectedDate,
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    createdAt: DateTime.now(),
                  );

                  final result = await _expenseService.createExpense(expense);

                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadReportData(); // Refresh data

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result != null
                              ? 'Expense added successfully!'
                              : 'Failed to add expense',
                        ),
                        backgroundColor:
                            result != null ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}