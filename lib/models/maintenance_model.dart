import 'package:cloud_firestore/cloud_firestore.dart';

enum MaintenanceStatus { pending, inProgress, fixed }
enum MaintenancePriority { low, medium, high, urgent }

class MaintenanceModel {
  final String id;
  final String tenantId;
  final String tenantName;
  final String landlordId;
  final String propertyId;
  final String unitId;
  final String title;
  final String description;
  final MaintenanceStatus status;
  final MaintenancePriority priority;
  final String? assignedTo; // Manager ID
  final String? responseNote;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? fixedAt;

  MaintenanceModel({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.landlordId,
    required this.propertyId,
    required this.unitId,
    required this.title,
    required this.description,
    required this.status,
    this.priority = MaintenancePriority.medium,
    this.assignedTo,
    this.responseNote,
    required this.createdAt,
    this.updatedAt,
    this.fixedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'tenantName': tenantName,
      'landlordId': landlordId,
      'propertyId': propertyId,
      'unitId': unitId,
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'assignedTo': assignedTo,
      'responseNote': responseNote,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'fixedAt': fixedAt != null ? Timestamp.fromDate(fixedAt!) : null,
    };
  }

  factory MaintenanceModel.fromMap(Map<String, dynamic> map) {
    return MaintenanceModel(
      id: map['id'] ?? '',
      tenantId: map['tenantId'] ?? '',
      tenantName: map['tenantName'] ?? '',
      landlordId: map['landlordId'] ?? '',
      propertyId: map['propertyId'] ?? '',
      unitId: map['unitId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: MaintenanceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MaintenanceStatus.pending,
      ),
      priority: MaintenancePriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => MaintenancePriority.medium,
      ),
      assignedTo: map['assignedTo'],
      responseNote: map['responseNote'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      fixedAt: map['fixedAt'] != null
          ? (map['fixedAt'] as Timestamp).toDate()
          : null,
    );
  }

  String get statusDisplay {
    switch (status) {
      case MaintenanceStatus.pending:
        return 'Pending';
      case MaintenanceStatus.inProgress:
        return 'In Progress';
      case MaintenanceStatus.fixed:
        return 'Fixed';
    }
  }

  String get priorityDisplay {
    switch (priority) {
      case MaintenancePriority.low:
        return 'Low';
      case MaintenancePriority.medium:
        return 'Medium';
      case MaintenancePriority.high:
        return 'High';
      case MaintenancePriority.urgent:
        return 'Urgent';
    }
  }
}