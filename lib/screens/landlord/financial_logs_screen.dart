import 'package:flutter/material.dart';
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

class FinancialLogsScreen extends StatefulWidget {
  const FinancialLogsScreen({super.key});

  @override
  State<FinancialLogsScreen> createState() => _FinancialLogsScreenState();
}

class _FinancialLogsScreenState extends State<FinancialLogsScreen> {
  final _searchController = TextEditingController();
  final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  String _searchQuery = '';
  String? _selectedPropertyId; // null = all properties
  PaymentStatus? _selectedStatus; // null = all statuses
  DateTimeRange? _dateRange;

  // Kept in sync on every build so the "Print PDF" app bar action can
  // export exactly what's currently on screen (respecting active
  // search/filters) without recomputing the filter logic separately.
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
        // Filter against paidDate when present (actual payment date),
        // otherwise fall back to dueDate so pending/overdue records
        // with no paidDate can still be found by date range.
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
      return bDate.compareTo(aDate); // most recent first
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Print / Export PDF',
            onPressed: _currentFiltered.isEmpty ? null : _exportPdf,
          ),
        ],
      ),
      body: Consumer<FinancialProvider>(
        builder: (context, provider, _) {
          final filtered = _applyFilters(provider.payments, provider);

          // Keep the export button in sync with whatever is currently
          // visible under the active filters.
          _currentFiltered = filtered;
          _currentProvider = provider;

          return Column(
            children: [
              _buildFilterBar(provider),
              _buildActiveFilterSummary(filtered.length),
              const Divider(height: 1),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No payment records match these filters'))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) => _buildLogRow(filtered[index], provider),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecordPaymentDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Record Payment'),
      ),
    );
  }

  Widget _buildFilterBar(FinancialProvider provider) {
    final propertyIds = provider.payments.map((p) => p.propertyId).toSet();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by tenant name or receipt number',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedPropertyId,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: 'Property',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All properties')),
                    ...propertyIds.map((id) {
                      final property = provider.propertyById(id);
                      return DropdownMenuItem(value: id, child: Text(property?.name ?? 'Unknown'));
                    }),
                  ],
                  onChanged: (value) => setState(() => _selectedPropertyId = value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<PaymentStatus?>(
                  initialValue: _selectedStatus,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All statuses')),
                    DropdownMenuItem(value: PaymentStatus.paid, child: Text('Paid')),
                    DropdownMenuItem(value: PaymentStatus.pending, child: Text('Pending')),
                    DropdownMenuItem(value: PaymentStatus.overdue, child: Text('Overdue')),
                  ],
                  onChanged: (value) => setState(() => _selectedStatus = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    _dateRange == null
                        ? 'Filter by date range'
                        : '${DateFormat('dd MMM yyyy').format(_dateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange!.end)}',
                  ),
                ),
              ),
              if (_dateRange != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear date filter',
                  onPressed: () => setState(() => _dateRange = null),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterSummary(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$count record${count == 1 ? '' : 's'}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
      ),
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
      dense: false,
      title: Row(
        children: [
          Expanded(
            child: Text(
              tenant?.fullName ?? 'Unknown tenant',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(payment.formattedAmount, style: const TextStyle(fontWeight: FontWeight.bold)),
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
            if (property?.location != null) Text(property!.location),
            Text(
              payment.paidDate != null
                  ? _dateTimeFormat.format(displayDate)
                  : 'Due ${_dateTimeFormat.format(displayDate)} (not yet paid)',
            ),
            Row(
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
                const SizedBox(width: 8),
                Text(
                  payment.methodDisplay,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (payment.receiptNumber != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Receipt: ${payment.receiptNumber}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      isThreeLine: true,
    );
  }

  Future<void> _exportPdf() async {
    final provider = _currentProvider;
    final logs = _currentFiltered;
    if (provider == null || logs.isEmpty) return;

    final doc = pw.Document();

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

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Jikah \u2014 Financial Logs',
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
          pw.SizedBox(height: 6),
          pw.Text('${logs.length} record${logs.length == 1 ? '' : 's'}'),
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
                p.receiptNumber ?? '\u2014',
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
                    Navigator.pop(dialogContext); // close loading
                    Navigator.pop(dialogContext); // close form

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
