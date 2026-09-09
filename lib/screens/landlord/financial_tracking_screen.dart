import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/financial_provider.dart';

class FinancialTrackingScreen extends StatefulWidget {
  const FinancialTrackingScreen({super.key});

  @override
  State<FinancialTrackingScreen> createState() =>
      _FinancialTrackingScreenState();
}

class _FinancialTrackingScreenState extends State<FinancialTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<FinancialProvider>().startTracking(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF report',
            onPressed: () => _exportPdf(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Live Transactions'),
            Tab(text: 'Arrears'),
            Tab(text: 'Paid in Advance'),
          ],
        ),
      ),
      body: Consumer<FinancialProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.payments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTransactionsTab(provider),
              _buildBalanceTab(provider.inArrears, isArrears: true),
              _buildBalanceTab(provider.inAdvance, isArrears: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionsTab(FinancialProvider provider) {
    final transactions = provider.recentTransactions;

    if (transactions.isEmpty) {
      return const Center(child: Text('No payments recorded yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final payment = transactions[index];
        final tenant = provider.tenantById(payment.tenantId);
        final unit = provider.unitById(payment.unitId);
        final property = provider.propertyById(payment.propertyId);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withValues(alpha: 0.15),
              child: const Icon(Icons.arrow_downward, color: Colors.green),
            ),
            title: Text(
              tenant?.fullName ?? 'Unknown tenant',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property?.name ?? 'Unknown property'),
                if (property?.location != null) Text(property!.location),
                Text('Room/Unit: ${unit?.unitNumber ?? 'Unknown'}'),
                // recentTransactions already guarantees paidDate != null
                Text(
                  _dateTimeFormat.format(payment.paidDate!),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            trailing: Text(
              payment.formattedAmount,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildBalanceTab(List<TenantBalance> balances, {required bool isArrears}) {
    if (balances.isEmpty) {
      return Center(
        child: Text(isArrears ? 'No tenants in arrears' : 'No tenants paid in advance'),
      );
    }

    final currencyFormat =
        NumberFormat.currency(locale: 'en_UG', symbol: 'UGX ', decimalDigits: 0);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: balances.length,
      itemBuilder: (context, index) {
        final b = balances[index];
        final amount = isArrears ? b.arrearsAmount : b.advanceAmount;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  (isArrears ? Colors.red : Colors.blue).withValues(alpha: 0.15),
              child: Icon(
                isArrears ? Icons.warning_amber : Icons.savings,
                color: isArrears ? Colors.red : Colors.blue,
              ),
            ),
            title: Text(
              b.tenant.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.property?.name ?? 'Unknown property'),
                Text('Room/Unit: ${b.unit?.unitNumber ?? 'Unknown'}'),
                Text('${b.monthsOwed} month(s) since lease start'),
              ],
            ),
            trailing: Text(
              currencyFormat.format(amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isArrears ? Colors.red : Colors.blue,
              ),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    final provider = context.read<FinancialProvider>();
    final transactions = provider.recentTransactions;
    final arrears = provider.inArrears;
    final advance = provider.inAdvance;
    final currencyFormat =
        NumberFormat.currency(locale: 'en_UG', symbol: 'UGX ', decimalDigits: 0);

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Jikah \u2014 Payment Report',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('Generated: ${_dateTimeFormat.format(DateTime.now())}'),
          pw.SizedBox(height: 16),

          pw.Header(level: 1, text: 'Recent Transactions'),
          pw.TableHelper.fromTextArray(
            headers: ['Tenant', 'Property', 'Room', 'Amount', 'Date/Time'],
            data: transactions.map((p) {
              final tenant = provider.tenantById(p.tenantId);
              final unit = provider.unitById(p.unitId);
              final property = provider.propertyById(p.propertyId);
              return [
                tenant?.fullName ?? 'Unknown',
                property?.name ?? 'Unknown',
                unit?.unitNumber ?? 'Unknown',
                p.formattedAmount,
                _dateTimeFormat.format(p.paidDate!),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),

          pw.Header(level: 1, text: 'Tenants in Arrears'),
          pw.TableHelper.fromTextArray(
            headers: ['Tenant', 'Property', 'Room', 'Months Owed', 'Amount Owed'],
            data: arrears.map((b) {
              return [
                b.tenant.fullName,
                b.property?.name ?? 'Unknown',
                b.unit?.unitNumber ?? 'Unknown',
                b.monthsOwed.toString(),
                currencyFormat.format(b.arrearsAmount),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),

          pw.Header(level: 1, text: 'Tenants Paid in Advance'),
          pw.TableHelper.fromTextArray(
            headers: ['Tenant', 'Property', 'Room', 'Credit Balance'],
            data: advance.map((b) {
              return [
                b.tenant.fullName,
                b.property?.name ?? 'Unknown',
                b.unit?.unitNumber ?? 'Unknown',
                currencyFormat.format(b.advanceAmount),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Jikah_Payment_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }
}