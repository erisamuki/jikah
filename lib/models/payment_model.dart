import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus { paid, pending, overdue }
enum PaymentMethod { mtnMomo, airtelMoney, bankCard, cash }

class PaymentModel {
  final String id;
  final String tenantId;
  final String landlordId;
  final String propertyId;
  final String unitId;
  final double amount;
  final PaymentStatus status;
  final PaymentMethod? method;
  final String? transactionId;
  final String? receiptNumber;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String monthYear; // e.g., "March 2026"
  final String? notes;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.tenantId,
    required this.landlordId,
    required this.propertyId,
    required this.unitId,
    required this.amount,
    required this.status,
    this.method,
    this.transactionId,
    this.receiptNumber,
    required this.dueDate,
    this.paidDate,
    required this.monthYear,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'landlordId': landlordId,
      'propertyId': propertyId,
      'unitId': unitId,
      'amount': amount,
      'status': status.name,
      'method': method?.name,
      'transactionId': transactionId,
      'receiptNumber': receiptNumber,
      'dueDate': Timestamp.fromDate(dueDate),
      'paidDate': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
      'monthYear': monthYear,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] ?? '',
      tenantId: map['tenantId'] ?? '',
      landlordId: map['landlordId'] ?? '',
      propertyId: map['propertyId'] ?? '',
      unitId: map['unitId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      method: map['method'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.name == map['method'],
              orElse: () => PaymentMethod.cash,
            )
          : null,
      transactionId: map['transactionId'],
      receiptNumber: map['receiptNumber'],
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      paidDate: map['paidDate'] != null
          ? (map['paidDate'] as Timestamp).toDate()
          : null,
      monthYear: map['monthYear'] ?? '',
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  String get statusDisplay {
    switch (status) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.overdue:
        return 'Overdue';
    }
  }

  String get methodDisplay {
    switch (method) {
      case PaymentMethod.mtnMomo:
        return 'MTN MoMo';
      case PaymentMethod.airtelMoney:
        return 'Airtel Money';
      case PaymentMethod.bankCard:
        return 'Bank Card';
      case PaymentMethod.cash:
        return 'Cash';
      default:
        return 'Not Paid';
    }
  }

  // Format amount in UGX
  String get formattedAmount {
    return 'UGX ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }
}