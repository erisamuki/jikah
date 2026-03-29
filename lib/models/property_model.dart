import 'package:cloud_firestore/cloud_firestore.dart';

enum PropertyType { hostel, rental, standaloneHouse, apartment, commercialBuilding }

class PropertyModel {
  final String id;
  final String landlordId;
  final String name;
  final String location;
  final String? address;
  final PropertyType type;
  final String? managerId;
  final String? description;
  final String? imageUrl;
  final int totalUnits;
  final int occupiedUnits;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  PropertyModel({
    required this.id,
    required this.landlordId,
    required this.name,
    required this.location,
    this.address,
    required this.type,
    this.managerId,
    this.description,
    this.imageUrl,
    this.totalUnits = 0,
    this.occupiedUnits = 0,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'landlordId': landlordId,
      'name': name,
      'location': location,
      'address': address,
      'type': type.name,
      'managerId': managerId,
      'description': description,
      'imageUrl': imageUrl,
      'totalUnits': totalUnits,
      'occupiedUnits': occupiedUnits,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
    };
  }

  factory PropertyModel.fromMap(Map<String, dynamic> map) {
    return PropertyModel(
      id: map['id'] ?? '',
      landlordId: map['landlordId'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      address: map['address'],
      type: PropertyType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PropertyType.rental,
      ),
      managerId: map['managerId'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      totalUnits: map['totalUnits'] ?? 0,
      occupiedUnits: map['occupiedUnits'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] ?? true,
    );
  }

  String get propertyTypeDisplay {
    switch (type) {
      case PropertyType.hostel:
        return 'Hostel';
      case PropertyType.rental:
        return 'Rental';
      case PropertyType.standaloneHouse:
        return 'Standalone House';
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.commercialBuilding:
        return 'Commercial Building';
    }
  }

  int get availableUnits => totalUnits - occupiedUnits;
}