import 'package:cloud_firestore/cloud_firestore.dart';

enum UnitStatus { vacant, occupied, maintenance }

class UnitModel {
  final String id;
  final String propertyId;
  final String landlordId;
  final String unitNumber;
  final String? description;
  final double rentAmount; // In UGX
  final UnitStatus status;
  final String? tenantId;
  final DateTime? leaseStartDate;
  final DateTime? leaseEndDate;
  final int? paymentDueDay; // Day of month rent is due (1-31)
  final DateTime createdAt;
  final DateTime? updatedAt;

  UnitModel({
    required this.id,
    required this.propertyId,
    required this.landlordId,
    required this.unitNumber,
    this.description,
    required this.rentAmount,
    this.status = UnitStatus.vacant,
    this.tenantId,
    this.leaseStartDate,
    this.leaseEndDate,
    this.paymentDueDay,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propertyId': propertyId,
      'landlordId': landlordId,
      'unitNumber': unitNumber,
      'description': description,
      'rentAmount': rentAmount,
      'status': status.name,
      'tenantId': tenantId,
      'leaseStartDate': leaseStartDate != null
          ? Timestamp.fromDate(leaseStartDate!)
          : null,
      'leaseEndDate':
          leaseEndDate != null ? Timestamp.fromDate(leaseEndDate!) : null,
      'paymentDueDay': paymentDueDay,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory UnitModel.fromMap(Map<String, dynamic> map) {
    return UnitModel(
      id: map['id'] ?? '',
      propertyId: map['propertyId'] ?? '',
      landlordId: map['landlordId'] ?? '',
      unitNumber: map['unitNumber'] ?? '',
      description: map['description'],
      rentAmount: (map['rentAmount'] ?? 0).toDouble(),
      status: UnitStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => UnitStatus.vacant,
      ),
      tenantId: map['tenantId'],
      leaseStartDate: map['leaseStartDate'] != null
          ? (map['leaseStartDate'] as Timestamp).toDate()
          : null,
      leaseEndDate: map['leaseEndDate'] != null
          ? (map['leaseEndDate'] as Timestamp).toDate()
          : null,
      paymentDueDay: map['paymentDueDay'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  String get statusDisplay {
    switch (status) {
      case UnitStatus.vacant:
        return 'Vacant';
      case UnitStatus.occupied:
        return 'Occupied';
      case UnitStatus.maintenance:
        return 'Under Maintenance';
    }
  }

  // Format rent in UGX
  String get formattedRent {
    return 'UGX ${rentAmount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }
}