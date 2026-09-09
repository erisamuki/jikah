import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../models/user_model.dart';
import '../models/unit_model.dart';
import '../models/property_model.dart';
import '../services/payment_service.dart';
import '../services/database_service.dart';

/// Represents a tenant's current balance standing: how much they owe
/// (arrears) or how much credit they have (paid in advance).
class TenantBalance {
  final UserModel tenant;
  final UnitModel? unit;
  final PropertyModel? property;
  final double expectedTotal;
  final double paidTotal;
  final double balance; // paidTotal - expectedTotal
  final int monthsOwed;

  TenantBalance({
    required this.tenant,
    required this.unit,
    required this.property,
    required this.expectedTotal,
    required this.paidTotal,
    required this.balance,
    required this.monthsOwed,
  });

  bool get isInArrears => balance < 0;
  bool get isInAdvance => balance > 0;
  bool get isCurrent => balance == 0;
  double get arrearsAmount => isInArrears ? balance.abs() : 0;
  double get advanceAmount => isInAdvance ? balance : 0;
}

class FinancialProvider extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();
  final DatabaseService _dbService = DatabaseService();

  List<PaymentModel> _payments = [];
  List<UserModel> _tenants = [];
  List<UnitModel> _units = [];
  List<PropertyModel> _properties = [];
  bool _isLoading = false;
  String? _error;

  List<PaymentModel> get payments => _payments;
  List<UserModel> get tenants => _tenants;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Only genuinely paid transactions, most recent first \u2014 this is the
  /// live transaction feed. Pending/overdue records have no paidDate.
  List<PaymentModel> get recentTransactions {
    final paid = _payments
        .where((p) => p.status == PaymentStatus.paid && p.paidDate != null)
        .toList();
    paid.sort((a, b) => b.paidDate!.compareTo(a.paidDate!));
    return paid;
  }

  // Start real-time listeners for everything needed to build the
  // financial tracking / logs screens. Firestore pushes updates
  // automatically, same pattern as PropertyProvider.
  void startTracking(String landlordId) {
    _isLoading = true;
    notifyListeners();

    _paymentService
        .getPaymentsByLandlord(landlordId)
        .listen(
          (paymentList) {
            _payments = paymentList;
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            _isLoading = false;
            notifyListeners();
          },
        );

    _dbService.getTenantsByLandlord(landlordId).listen((tenantList) {
      _tenants = tenantList;
      notifyListeners();
    });

    _dbService.getUnitsByLandlord(landlordId).listen((unitList) {
      _units = unitList;
      notifyListeners();
    });

    _dbService.getPropertiesByLandlord(landlordId).listen((propertyList) {
      _properties = propertyList;
      notifyListeners();
    });
  }

  UnitModel? _unitFor(String unitId) {
    try {
      return _units.firstWhere((u) => u.id == unitId);
    } catch (_) {
      return null;
    }
  }

  PropertyModel? _propertyFor(String propertyId) {
    try {
      return _properties.firstWhere((p) => p.id == propertyId);
    } catch (_) {
      return null;
    }
  }

  /// Number of calendar months from [start] to today, inclusive of the
  /// current month. E.g. leaseStartDate = March, today = May -> 3.
  int _monthsSince(DateTime start) {
    final now = DateTime.now();
    final months = (now.year - start.year) * 12 + (now.month - start.month) + 1;
    return months < 1 ? 1 : months;
  }

  /// Computes arrears/advance for every active tenant. Call this from a
  /// getter in the UI (e.g. via Consumer) rather than caching, since it
  /// needs to stay in sync with whichever of payments/tenants/units
  /// changed most recently.
  List<TenantBalance> get tenantBalances {
    final List<TenantBalance> result = [];

    for (final tenant in _tenants) {
      if (tenant.assignedUnitId == null || tenant.assignedPropertyId == null) {
        continue; // no active lease, nothing to calculate
      }

      final unit = _unitFor(tenant.assignedUnitId!);
      final property = _propertyFor(tenant.assignedPropertyId!);
      if (unit == null) continue;

      // Fall back to the tenant's account creation date if no explicit
      // lease start date has been recorded yet.
      final leaseStart = tenant.leaseStartDate ?? tenant.createdAt;
      final monthsOwed = _monthsSince(leaseStart);
      final expectedTotal = unit.rentAmount * monthsOwed;

      final paidTotal = _payments
          .where((p) => p.tenantId == tenant.uid && p.status == PaymentStatus.paid)
          .fold(0.0, (sum, p) => sum + p.amount);

      result.add(
        TenantBalance(
          tenant: tenant,
          unit: unit,
          property: property,
          expectedTotal: expectedTotal,
          paidTotal: paidTotal,
          balance: paidTotal - expectedTotal,
          monthsOwed: monthsOwed,
        ),
      );
    }

    return result;
  }

  List<TenantBalance> get inArrears =>
      tenantBalances.where((b) => b.isInArrears).toList()
        ..sort((a, b) => a.balance.compareTo(b.balance)); // worst first

  List<TenantBalance> get inAdvance =>
      tenantBalances.where((b) => b.isInAdvance).toList()
        ..sort((a, b) => b.balance.compareTo(a.balance)); // highest credit first

  double get totalArrears => inArrears.fold(0.0, (sum, b) => sum + b.arrearsAmount);

  double get totalAdvance => inAdvance.fold(0.0, (sum, b) => sum + b.advanceAmount);

  // Lookup helpers for the transaction list UI
  UserModel? tenantById(String tenantId) {
    try {
      return _tenants.firstWhere((t) => t.uid == tenantId);
    } catch (_) {
      return null;
    }
  }

  UnitModel? unitById(String unitId) => _unitFor(unitId);
  PropertyModel? propertyById(String propertyId) => _propertyFor(propertyId);

  /// Records a payment the admin (landlord) enters by hand \u2014 e.g. cash
  /// handed over in person, or a bank transfer that didn't come through
  /// a mobile money webhook. Property/unit are resolved from the
  /// tenant's current assignment rather than asked for separately.
  /// Due date defaults to the unit's configured payment-due day for the
  /// paid month, falling back to the paid date itself if the unit can't
  /// be resolved.
  Future<bool> recordManualPayment({
    required String landlordId,
    required String tenantId,
    required double amount,
    required PaymentMethod method,
    required String monthYear,
    required DateTime paidDate,
    String? notes,
  }) async {
    final tenant = tenantById(tenantId);
    if (tenant == null || tenant.assignedPropertyId == null || tenant.assignedUnitId == null) {
      _error = 'Selected tenant has no assigned property/unit';
      notifyListeners();
      return false;
    }

    final unit = _unitFor(tenant.assignedUnitId!);
    final dueDate = unit?.paymentDueDay != null
        ? DateTime(paidDate.year, paidDate.month, unit!.paymentDueDay!)
        : paidDate;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final payment = PaymentModel(
        id: '', // overwritten with the real doc id on read
        tenantId: tenantId,
        landlordId: landlordId,
        propertyId: tenant.assignedPropertyId!,
        unitId: tenant.assignedUnitId!,
        amount: amount,
        status: PaymentStatus.paid,
        method: method,
        transactionId: 'MANUAL${now.millisecondsSinceEpoch}',
        receiptNumber: 'RCP${now.millisecondsSinceEpoch}',
        dueDate: dueDate,
        paidDate: paidDate,
        monthYear: monthYear,
        notes: notes,
        createdAt: now,
      );

      final paymentId = await _paymentService.createPayment(payment);

      _isLoading = false;
      if (paymentId == null) {
        _error = 'Failed to record payment';
        notifyListeners();
        return false;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
