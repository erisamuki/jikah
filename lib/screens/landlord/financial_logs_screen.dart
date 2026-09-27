import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/financial_provider.dart';
import '../../models/payment_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

const double _wideScreenBreakpoint = 800;

class FinancialLogsScreen extends StatefulWidget {
  const FinancialLogsScreen({super.key});

  @override
  State<FinancialLogsScreen> createState() => _FinancialLogsScreenState();
}

class _FinancialLogsScreenState extends State<FinancialLogsScreen> {
  final _searchController = TextEditingController();
  final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  final _currencyFormat = NumberFormat.currency(locale: 'en_UG', symbol: 'UGX ', decimalDigits: 0);

  String _searchQuery = '';
  String? _selectedPropertyId;
  PaymentStatus? _selectedStatus;
  DateTimeRange? _dateRange;

  List<PaymentModel> _currentFiltered = [];
  FinancialProvider? _currentProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<FinancialProvider>().startTracking(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PaymentModel> _applyFilters(List<PaymentModel> payments, FinancialProvider provider) {
    return payments.where((p) {
      if (_selectedStatus != null && p.status != _selectedStatus) return false;
      if (_selectedPropertyId != null && p.propertyId != _selectedPropertyId) return false;

      if (_dateRange != null) {
        final reference = p.paidDate ?? p.dueDate;
        final d = DateTime(reference.year, reference.month, reference.day);
        final start = DateTime(
          _dateRange!.start.year,
          _dateRange!.start.month,
          _dateRange!.start.day,
        );
        final end = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day);
        if (d.isBefore(start) || d.isAfter(end)) return false;
      }

      if (_searchQuery.trim().isNotEmpty) {
        final tenant = provider.tenantById(p.tenantId);
        final name = tenant?.fullName.toLowerCase() ?? '';
        final receipt = (p.receiptNumber ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        if (!name.contains(query) && !receipt.contains(query)) return false;
      }

      return true;
    }).toList()..sort((a, b) {
      final aDate = a.paidDate ?? a.dueDate;
      final bDate = b.paidDate ?? b.dueDate;
      return bDate.compareTo(aDate);
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  bool get _hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
      _selectedPropertyId != null ||
      _selectedStatus != null ||
      _dateRange != null;

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedPropertyId = null;
      _selectedStatus = null;
      _dateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'export-pdf',
            mini: true,
            onPressed: _currentFiltered.isEmpty ? null : _exportPdf,
            tooltip: 'Print / Export PDF',
            backgroundColor: _currentFiltered.isEmpty
                ? Colors.grey.shade400
                : Theme.of(context).primaryColor,
            child: const Icon(Icons.picture_as_pdf),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'record-payment',
            onPressed: () => _showRecordPaymentDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Record Payment'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > _wideScreenBreakpoint;

          return Consumer<FinancialProvider>(
            builder: (context, provider, _) {
              final filtered = _applyFilters(provider.payments, provider);
              _currentFiltered = filtered;
              _currentProvider = provider;

              return Column(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isWide ? 1100 : double.infinity),
                      child: _buildFilterBar(provider, isWide),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 4),
                    child: Align(
                      alignment: isWide ? Alignment.center : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isWide ? 1100 : double.infinity),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _buildActiveFilterSummary(filtered.length),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              _hasActiveFilters
                                  ? 'No payment records match these filters'
                                  : 'No payment records yet',
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 96),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isWide ? 1100 : double.infinity,
                                ),
                                child: Column(
                                  children: [
                                    for (int i = 0; i < filtered.length; i++) ...[
                                      _buildLogRow(filtered[i], provider),
                                      if (i != filtered.length - 1) const Divider(height: 1),
                                    ],
                                  ],
                                ),
                              ),
                            ),
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

  Widget _buildFilterBar(FinancialProvider provider, bool isWide) {
    final propertyIds = provider.payments.map((p) => p.propertyId).toSet();

    final searchField = TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search tenant name or receipt no.',
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
      ),
      onChanged: (value) => setState(() => _searchQuery = value),
    );

    final propertyDropdown = DropdownButtonFormField<String?>(
      initialValue: _selectedPropertyId,
      isDense: true,
      decoration: InputDecoration(
        labelText: 'Property',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('All properties')),
        ...propertyIds.map((id) {
          final property = provider.propertyById(id);
          return DropdownMenuItem(
            value: id,
            child: Text(property?.name ?? 'Unknown', overflow: TextOverflow.ellipsis),
          );
        }),
      ],
      onChanged: (value) => setState(() => _selectedPropertyId = value),
    );

    final statusDropdown = DropdownButtonFormField<PaymentStatus?>(
      initialValue: _selectedStatus,
      isDense: true,
      decoration: InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('All statuses')),
        DropdownMenuItem(value: PaymentStatus.paid, child: Text('Paid')),
        DropdownMenuItem(value: PaymentStatus.pending, child: Text('Pending')),
        DropdownMenuItem(value: PaymentStatus.overdue, child: Text('Overdue')),
      ],
      onChanged: (value) => setState(() => _selectedStatus = value),
    );

    final dateRangeButton = OutlinedButton.icon(
      onPressed: _pickDateRange,
      icon: const Icon(Icons.date_range, size: 18),
      label: Text(
        _dateRange == null
            ? 'Date range'
            : '${DateFormat('dd MMM').format(_dateRange!.start)} \u2013 ${DateFormat('dd MMM yyyy').format(_dateRange!.end)}',
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    final clearButton = _hasActiveFilters
        ? TextButton(onPressed: _clearAllFilters, child: const Text('Clear'))
        : const SizedBox.shrink();

    if (isWide) {
      // Everything fits comfortably on one row on a PC-sized window.
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 3, child: searchField),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: propertyDropdown),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: statusDropdown),
            const SizedBox(width: 12),
            SizedBox(width: 220, child: dateRangeButton),
            if (_hasActiveFilters) ...[const SizedBox(width: 4), clearButton],
          ],
        ),
      );
    }

    // Narrow / phone layout: stacked, full width.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: searchField),
              if (_hasActiveFilters) ...[const SizedBox(width: 8), clearButton],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: propertyDropdown),
              const SizedBox(width: 10),
              Expanded(child: statusDropdown),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: dateRangeButton),
          if (_dateRange != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _dateRange = null),
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear date filter'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterSummary(int count) {
    return Text(
      '$count record${count == 1 ? '' : 's'}',
      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildLogRow(PaymentModel payment, FinancialProvider provider) {
    final tenant = provider.tenantById(payment.tenantId);
    final unit = provider.unitById(payment.unitId);
    final property = provider.propertyById(payment.propertyId);

    Color statusColor;
    switch (payment.status) {
      case PaymentStatus.paid:
        statusColor = Colors.green;
        break;
      case PaymentStatus.pending:
        statusColor = Colors.orange;
        break;
      case PaymentStatus.overdue:
        statusColor = Colors.red;
        break;
    }

    final displayDate = payment.paidDate ?? payment.dueDate;

    return ListTile(
      onTap: () => _showEditPaymentDialog(context, payment, provider),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: Row(
        children: [
          Expanded(
            child: Text(
              tenant?.fullName ?? 'Unknown tenant',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(payment.formattedAmount, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Icon(Icons.edit, size: 16, color: Colors.grey.shade400),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${property?.name ?? 'Unknown property'} \u2014 Room/Unit: ${unit?.unitNumber ?? 'Unknown'}',
            ),
            if (property?.location != null)
              Text(property!.location, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            Text(
              payment.paidDate != null
                  ? _dateTimeFormat.format(displayDate)
                  : 'Due ${_dateTimeFormat.format(displayDate)} (not yet paid)',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    payment.statusDisplay.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  payment.methodDisplay,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (payment.receiptNumber != null)
                  Text(
                    'Receipt: ${payment.receiptNumber}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ),
      isThreeLine: true,
    );
  }

  /// Loads a Unicode-capable font for the PDF (default Helvetica silently
  /// drops characters like "—" used in this report's headers, logging a
  /// console warning instead of rendering them).
  ///
  /// Requires two font assets bundled in pubspec.yaml:
  ///   assets:
  ///     - assets/fonts/NotoSans-Regular.ttf
  ///     - assets/fonts/NotoSans-Bold.ttf
  /// Falls back to the default theme if the assets aren't found, so a
  /// missing font doesn't crash export.
  Future<pw.ThemeData?> _loadPdfTheme() async {
    try {
      final regularData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
      return pw.ThemeData.withFont(base: pw.Font.ttf(regularData), bold: pw.Font.ttf(boldData));
    } catch (e) {
      debugPrint('PDF font assets not found, falling back to default font: $e');
      return null;
    }
  }

  Future<void> _exportPdf() async {
    final provider = _currentProvider;
    final logs = _currentFiltered;
    if (provider == null || logs.isEmpty) return;

    final theme = await _loadPdfTheme();
    final doc = theme != null ? pw.Document(theme: theme) : pw.Document();

    final filterLines = <String>[];
    if (_searchQuery.trim().isNotEmpty) {
      filterLines.add('Search: "${_searchQuery.trim()}"');
    }
    if (_selectedPropertyId != null) {
      final name = provider.propertyById(_selectedPropertyId!)?.name ?? 'Unknown';
      filterLines.add('Property: $name');
    }
    if (_selectedStatus != null) {
      filterLines.add('Status: ${_selectedStatus!.name}');
    }
    if (_dateRange != null) {
      filterLines.add(
        'Date range: ${DateFormat('dd MMM yyyy').format(_dateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange!.end)}',
      );
    }

    // Totals summary so the landlord can read the report and understand
    // the numbers at a glance, without having to add up rows themselves.
    final paidLogs = logs.where((p) => p.status == PaymentStatus.paid).toList();
    final pendingLogs = logs.where((p) => p.status == PaymentStatus.pending).toList();
    final overdueLogs = logs.where((p) => p.status == PaymentStatus.overdue).toList();
    final totalAmount = logs.fold(0.0, (sum, p) => sum + p.amount);
    final paidAmount = paidLogs.fold(0.0, (sum, p) => sum + p.amount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Jikah — Financial Logs',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text('Generated: ${_dateTimeFormat.format(DateTime.now())}'),
          if (filterLines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'Filters applied: ${filterLines.join(" | ")}',
              style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10),
            ),
          ],
          pw.SizedBox(height: 12),

          // Totals block
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Summary',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Total records: ${logs.length}'),
                pw.Text('Total amount (all records): ${_currencyFormat.format(totalAmount)}'),
                pw.Text(
                  'Paid: ${paidLogs.length} record${paidLogs.length == 1 ? '' : 's'} — '
                  '${_currencyFormat.format(paidAmount)}',
                ),
                pw.Text(
                  'Pending: ${pendingLogs.length} record${pendingLogs.length == 1 ? '' : 's'}',
                ),
                pw.Text(
                  'Overdue: ${overdueLogs.length} record${overdueLogs.length == 1 ? '' : 's'}',
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          pw.TableHelper.fromTextArray(
            headers: [
              'Tenant',
              'Property',
              'Room',
              'Amount',
              'Date/Time',
              'Method',
              'Status',
              'Receipt',
            ],
            data: logs.map((p) {
              final tenant = provider.tenantById(p.tenantId);
              final unit = provider.unitById(p.unitId);
              final property = provider.propertyById(p.propertyId);
              final displayDate = p.paidDate ?? p.dueDate;
              return [
                tenant?.fullName ?? 'Unknown',
                property?.name ?? 'Unknown',
                unit?.unitNumber ?? 'Unknown',
                p.formattedAmount,
                _dateTimeFormat.format(displayDate),
                p.methodDisplay,
                p.statusDisplay,
                p.receiptNumber ?? '—',
              ];
            }).toList(),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Jikah_Financial_Logs_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }

  /// Lets the landlord correct a payment they already logged — wrong
  /// amount, wrong month, mistyped date, etc. Reuses the same field
  /// layout as the record-payment dialog but pre-filled, and calls
  /// FinancialProvider.editPayment instead of recordManualPayment.
  /// Tenant/property/unit are not editable here — if that was wrong,
  /// the record should be deleted and re-entered against the right
  /// tenant instead of reassigned.
  void _showEditPaymentDialog(
    BuildContext context,
    PaymentModel payment,
    FinancialProvider provider,
  ) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(text: payment.amount.toStringAsFixed(0));
    final monthYearController = TextEditingController(text: payment.monthYear);
    final notesController = TextEditingController(text: payment.notes ?? '');

    PaymentMethod selectedMethod = payment.method ?? PaymentMethod.cash;
    DateTime selectedDateTime = payment.paidDate ?? payment.dueDate;

    final tenant = provider.tenantById(payment.tenantId);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text('Edit Payment${tenant != null ? ' — ${tenant.fullName}' : ''}'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomTextField(
                        controller: amountController,
                        label: 'Amount (UGX)',
                        prefixIcon: Icons.payments,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Required';
                          if (double.tryParse(v!) == null) return 'Enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<PaymentMethod>(
                        initialValue: selectedMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                          prefixIcon: Icon(Icons.account_balance_wallet),
                        ),
                        items: const [
                          DropdownMenuItem(value: PaymentMethod.cash, child: Text('Cash')),
                          DropdownMenuItem(value: PaymentMethod.bankCard, child: Text('Bank Card')),
                          DropdownMenuItem(
                            value: PaymentMethod.mtnMomo,
                            child: Text('MTN Mobile Money'),
                          ),
                          DropdownMenuItem(
                            value: PaymentMethod.airtelMoney,
                            child: Text('Airtel Money'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => selectedMethod = value ?? selectedMethod),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: monthYearController,
                        label: 'Month Covered (e.g. March 2026)',
                        prefixIcon: Icons.calendar_month,
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: dialogContext,
                            initialDate: selectedDateTime,
                            firstDate: DateTime(DateTime.now().year - 3),
                            lastDate: DateTime.now(),
                          );
                          if (date == null) return;
                          if (!dialogContext.mounted) return;
                          final time = await showTimePicker(
                            context: dialogContext,
                            initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                          );
                          setState(() {
                            selectedDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time?.hour ?? selectedDateTime.hour,
                              time?.minute ?? selectedDateTime.minute,
                            );
                          });
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date & Time Paid',
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          child: Text(DateFormat('dd MMM yyyy, hh:mm a').format(selectedDateTime)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: notesController,
                        label: 'Notes (Optional)',
                        prefixIcon: Icons.note,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: dialogContext,
                    builder: (confirmContext) => AlertDialog(
                      title: const Text('Delete this payment?'),
                      content: Text(
                        'This will permanently remove ${tenant?.fullName ?? 'this'}\'s '
                        '${payment.formattedAmount} payment record. This cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(confirmContext, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(confirmContext, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;
                  if (!dialogContext.mounted) return;

                  showDialog(
                    context: dialogContext,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  final success = await provider.deletePayment(payment.id);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext); // loading spinner
                    Navigator.pop(dialogContext); // edit dialog

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Payment deleted'
                              : provider.error ?? 'Failed to delete payment',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              CustomButton(
                text: 'Save Changes',
                onPressed: () async {
                  if (!(formKey.currentState?.validate() ?? false)) return;

                  showDialog(
                    context: dialogContext,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  final success = await provider.editPayment(
                    payment.id,
                    amount: double.parse(amountController.text),
                    method: selectedMethod,
                    monthYear: monthYearController.text.trim(),
                    paidDate: selectedDateTime,
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  );

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Payment updated successfully'
                              : provider.error ?? 'Failed to update payment',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRecordPaymentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final monthYearController = TextEditingController(
      text: DateFormat('MMMM yyyy').format(DateTime.now()),
    );
    final notesController = TextEditingController();

    String? selectedTenantId;
    PaymentMethod selectedMethod = PaymentMethod.cash;
    DateTime selectedDateTime = DateTime.now();

    final user = context.read<AuthProvider>().currentUser;
    final provider = context.read<FinancialProvider>();

    if (user == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('Record Payment'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedTenantId,
                        decoration: const InputDecoration(
                          labelText: 'Tenant',
                          prefixIcon: Icon(Icons.person),
                        ),
                        items: provider.tenants.map((t) {
                          return DropdownMenuItem(value: t.uid, child: Text(t.fullName));
                        }).toList(),
                        onChanged: (value) => setState(() => selectedTenantId = value),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: amountController,
                        label: 'Amount (UGX)',
                        prefixIcon: Icons.payments,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Required';
                          if (double.tryParse(v!) == null) return 'Enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<PaymentMethod>(
                        initialValue: selectedMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                          prefixIcon: Icon(Icons.account_balance_wallet),
                        ),
                        items: const [
                          DropdownMenuItem(value: PaymentMethod.cash, child: Text('Cash')),
                          DropdownMenuItem(value: PaymentMethod.bankCard, child: Text('Bank Card')),
                          DropdownMenuItem(
                            value: PaymentMethod.mtnMomo,
                            child: Text('MTN Mobile Money'),
                          ),
                          DropdownMenuItem(
                            value: PaymentMethod.airtelMoney,
                            child: Text('Airtel Money'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => selectedMethod = value ?? PaymentMethod.cash),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: monthYearController,
                        label: 'Month Covered (e.g. March 2026)',
                        prefixIcon: Icons.calendar_month,
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: dialogContext,
                            initialDate: selectedDateTime,
                            firstDate: DateTime(DateTime.now().year - 3),
                            lastDate: DateTime.now(),
                          );
                          if (date == null) return;
                          if (!dialogContext.mounted) return;
                          final time = await showTimePicker(
                            context: dialogContext,
                            initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                          );
                          setState(() {
                            selectedDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time?.hour ?? selectedDateTime.hour,
                              time?.minute ?? selectedDateTime.minute,
                            );
                          });
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date & Time Paid',
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          child: Text(DateFormat('dd MMM yyyy, hh:mm a').format(selectedDateTime)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: notesController,
                        label: 'Notes (Optional)',
                        prefixIcon: Icons.note,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              CustomButton(
                text: 'Record Payment',
                onPressed: () async {
                  if (!(formKey.currentState?.validate() ?? false)) return;

                  showDialog(
                    context: dialogContext,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  final success = await provider.recordManualPayment(
                    landlordId: user.uid,
                    tenantId: selectedTenantId!,
                    amount: double.parse(amountController.text),
                    method: selectedMethod,
                    monthYear: monthYearController.text.trim(),
                    paidDate: selectedDateTime,
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  );

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Payment recorded successfully'
                              : provider.error ?? 'Failed to record payment',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
