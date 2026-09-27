import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { landlord, manager, tenant }

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final String? profileImageUrl;
  final String? assignedLandlordId; // For managers/tenants
  final String? assignedPropertyId; // For managers/tenants
  final String? assignedUnitId; // For tenants
  final String? ninOrPassport; // National ID or Passport
  final String? nextOfKin; // For tenants
  final String? nextOfKinContact;
  final DateTime? leaseStartDate; // For tenants — used for arrears/advance calc
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String fcmToken;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImageUrl,
    this.assignedLandlordId,
    this.assignedPropertyId,
    this.assignedUnitId,
    this.ninOrPassport,
    this.nextOfKin,
    this.nextOfKinContact,
    this.leaseStartDate,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    required this.fcmToken,
  });

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role.name,
      'profileImageUrl': profileImageUrl,
      'assignedLandlordId': assignedLandlordId,
      'assignedPropertyId': assignedPropertyId,
      'assignedUnitId': assignedUnitId,
      'ninOrPassport': ninOrPassport,
      'nextOfKin': nextOfKin,
      'nextOfKinContact': nextOfKinContact,
      'leaseStartDate': leaseStartDate != null ? Timestamp.fromDate(leaseStartDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'fcmToken': fcmToken,
    };
  }

  // Create from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRole.values.firstWhere((e) => e.name == map['role'], orElse: () => UserRole.tenant),
      profileImageUrl: map['profileImageUrl'],
      assignedLandlordId: map['assignedLandlordId'],
      assignedPropertyId: map['assignedPropertyId'],
      assignedUnitId: map['assignedUnitId'],
      ninOrPassport: map['ninOrPassport'],
      nextOfKin: map['nextOfKin'],
      nextOfKinContact: map['nextOfKinContact'],
      leaseStartDate: map['leaseStartDate'] != null
          ? (map['leaseStartDate'] as Timestamp).toDate()
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
      isActive: map['isActive'] ?? true,
      fcmToken: map['fcmToken'] ?? '',
    );
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? profileImageUrl,
    String? assignedLandlordId,
    String? assignedPropertyId,
    String? assignedUnitId,
    String? ninOrPassport,
    String? nextOfKin,
    String? nextOfKinContact,
    DateTime? leaseStartDate,
    bool? isActive,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      assignedLandlordId: assignedLandlordId ?? this.assignedLandlordId,
      assignedPropertyId: assignedPropertyId ?? this.assignedPropertyId,
      assignedUnitId: assignedUnitId ?? this.assignedUnitId,
      ninOrPassport: ninOrPassport ?? this.ninOrPassport,
      nextOfKin: nextOfKin ?? this.nextOfKin,
      nextOfKinContact: nextOfKinContact ?? this.nextOfKinContact,
      leaseStartDate: leaseStartDate ?? this.leaseStartDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isActive: isActive ?? this.isActive,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
