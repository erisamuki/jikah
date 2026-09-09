import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/financial_provider.dart';

// Same breakpoint LandlordHomeScreen uses for its sidebar/drawer switch,
// kept in sync so "wide" means the same thing everywhere in the app.
const double _wideScreenBreakpoint = 800;

class FinancialTrackingScreen extends StatefulWidget {
  const FinancialTrackingScreen({super.key});

  @override
  State<FinancialTrackingScreen> createState() => _FinancialTrackingScreenState();
}

class _FinancialTrackingScreenState extends State<FinancialTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  final _currencyFormat = NumberFormat.currency(locale: 'en_UG', symbol: 'UGX ', decimalDigits: 0);

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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _exportPdf(context),
        tooltip: 'Export PDF report',
        child: const Icon(Icons.picture_as_pdf),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > _wideScreenBreakpoint;

          return Consumer<FinancialProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.payments.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [
                  Material(
                    color: Theme.of(context).primaryColor,
                    child: TabBar(
                      controller: _tabController,
                      // Wide screens have room for fixed, evenly-spaced
                      // tabs; narrow screens scroll so labels never clip.
                      isScrollable: !isWide,
                      tabAlignment: isWide ? TabAlignment.fill : TabAlignment.start,
                      indicatorWeight: 3,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isWide ? 14 : 13,
                      ),
                      tabs: const [
                        Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'Transactions'),
                        Tab(icon: Icon(Icons.warning_amber, size: 18), text: 'Arrears'),
                        Tab(icon: Icon(Icons.savings, size: 18), text: 'Advance'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTransactionsTab(provider, isWide),
                        _buildBalanceTab(
                          provider.inArrears,
                          isArrears: true,
                          provider: provider,
                          isWide: isWide,
                        ),
                        _buildBalanceTab(
                          provider.inAdvance,
                          isArrears: false,
                          provider: provider,
                          isWide: isWide,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Centers content and caps its width on wide screens, so cards don't
  /// stretch edge-to-edge across a large monitor. On narrow screens this
  /// is a no-op (full width).
  Widget _constrained({required bool isWide, required Widget child}) {
    if (!isWide) return child;
    return Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: child),
    );
  }

  Widget _summaryStrip({
    required IconData icon,
    required Color color,
    required String text,
    required bool isWide,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 12),
      color: color.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(FinancialProvider provider, bool isWide) {
    final transactions = provider.recentTransactions;

    if (transactions.isEmpty) {
      return const Center(child: Text('No payments recorded yet'));
    }

    return Column(
      children: [
        _summaryStrip(
          icon: Icons.receipt_long,
          color: Colors.green.shade700,
          text: '${transactions.length} payment${transactions.length == 1 ? '' : 's'} recorded',
          isWide: isWide,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: _constrained(
              isWide: isWide,
              child: Padding(
                padding: EdgeInsets.all(isWide ? 24 : 16),
                child: Column(
                  children: transactions.map((payment) {
                    final tenant = provider.tenantById(payment.tenantId);
                    final unit = provider.unitById(payment.unitId);
                    final property = provider.propertyById(payment.propertyId);

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            const SizedBox(height: 2),
                            Text(
                              '${property?.name ?? 'Unknown property'} \u2022 Room/Unit ${unit?.unitNumber ?? 'Unknown'}',
                            ),
                            if (property?.location != null)
                              Text(
                                property!.location,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              _dateTimeFormat.format(payment.paidDate!),
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Text(
                          payment.formattedAmount,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceTab(
    List<TenantBalance> balances, {
    required bool isArrears,
    required FinancialProvider provider,
    required bool isWide,
  }) {
    if (balances.isEmpty) {
      return Center(
        child: Text(isArrears ? 'No tenants in arrears' : 'No tenants paid in advance'),
      );
    }

    final total = isArrears ? provider.totalArrears : provider.totalAdvance;
    final color = isArrears ? Colors.red.shade700 : Colors.blue.shade700;

    return Column(
      children: [
        _summaryStrip(
          icon: isArrears ? Icons.warning_amber : Icons.savings,
          color: color,
          text:
              '${balances.length} tenant${balances.length == 1 ? '' : 's'} \u2014 '
              'Total ${isArrears ? 'owed' : 'credit'}: ${_currencyFormat.format(total)}',
          isWide: isWide,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: _constrained(
              isWide: isWide,
              child: Padding(
                padding: EdgeInsets.all(isWide ? 24 : 16),
                child: Column(
                  children: balances.map((b) {
                    final amount = isArrears ? b.arrearsAmount : b.advanceAmount;

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Icon(
                            isArrears ? Icons.warning_amber : Icons.savings,
                            color: color,
                          ),
                        ),
                        title: Text(
                          b.tenant.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              '${b.property?.name ?? 'Unknown property'} \u2022 Room/Unit ${b.unit?.unitNumber ?? 'Unknown'}',
                            ),
                            Text(
                              '${b.monthsOwed} month(s) since lease start',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Text(
                          _currencyFormat.format(amount),
                          style: TextStyle(fontWeight: FontWeight.bold, color: color),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    final provider = context.read<FinancialProvider>();
    final transactions = provider.recentTransactions;
    final arrears = provider.inArrears;
    final advance = provider.inAdvance;

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Jikah \u2014 Payment Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
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
                _currencyFormat.format(b.arrearsAmount),
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
                _currencyFormat.format(b.advanceAmount),
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
