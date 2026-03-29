import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseCategory { maintenance, utilities, taxes, insurance, management, other }

class ExpenseModel {
  final String id;
  final String landlordId;
  final String? propertyId;
  final String title;
  final String? description;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? receiptUrl;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.landlordId,
    this.propertyId,
    required this.title,
    this.description,
    required this.amount,
    required this.category,
    required this.date,
    this.receiptUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'landlordId': landlordId,
      'propertyId': propertyId,
      'title': title,
      'description': description,
      'amount': amount,
      'category': category.name,
      'date': Timestamp.fromDate(date),
      'receiptUrl': receiptUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] ?? '',
      landlordId: map['landlordId'] ?? '',
      propertyId: map['propertyId'],
      title: map['title'] ?? '',
      description: map['description'],
      amount: (map['amount'] ?? 0).toDouble(),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      date: (map['date'] as Timestamp).toDate(),
      receiptUrl: map['receiptUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  String get categoryDisplay {
    switch (category) {
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.taxes:
        return 'Taxes';
      case ExpenseCategory.insurance:
        return 'Insurance';
      case ExpenseCategory.management:
        return 'Management';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  String get formattedAmount {
    return 'UGX ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }
}