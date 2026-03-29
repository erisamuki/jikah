import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/property_model.dart';
import '../models/unit_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USER OPERATIONS ====================

  // Get user by ID
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore.collection('users').doc(uid).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get managers by landlord
  Stream<List<UserModel>> getManagersByLandlord(String landlordId) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: UserRole.manager.name)
        .where('assignedLandlordId', isEqualTo: landlordId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList());
  }

  // Get tenants by landlord
  Stream<List<UserModel>> getTenantsByLandlord(String landlordId) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: UserRole.tenant.name)
        .where('assignedLandlordId', isEqualTo: landlordId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList());
  }

  // Get tenants by property
  Stream<List<UserModel>> getTenantsByProperty(String propertyId) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: UserRole.tenant.name)
        .where('assignedPropertyId', isEqualTo: propertyId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList());
  }

  // Deactivate user (soft delete)
  Future<bool> deactivateUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== PROPERTY OPERATIONS ====================

  // Create property
  Future<String?> createProperty(PropertyModel property) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('properties').add(property.toMap());
      
      // Update with generated ID
      await docRef.update({'id': docRef.id});
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  // Get property by ID
  Future<PropertyModel?> getProperty(String propertyId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('properties').doc(propertyId).get();
      if (!doc.exists) return null;
      return PropertyModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // Get properties by landlord
  Stream<List<PropertyModel>> getPropertiesByLandlord(String landlordId) {
    return _firestore
        .collection('properties')
        .where('landlordId', isEqualTo: landlordId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PropertyModel.fromMap(doc.data()))
            .toList());
  }

  // Get property by manager
  Future<PropertyModel?> getPropertyByManager(String managerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('properties')
          .where('managerId', isEqualTo: managerId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return PropertyModel.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // Update property
  Future<bool> updateProperty(String propertyId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore.collection('properties').doc(propertyId).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Deactivate property (soft delete)
  Future<bool> deactivateProperty(String propertyId) async {
    try {
      await _firestore.collection('properties').doc(propertyId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== UNIT OPERATIONS ====================

  // Create unit
  Future<String?> createUnit(UnitModel unit) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('units').add(unit.toMap());
      
      // Update with generated ID
      await docRef.update({'id': docRef.id});

      // Update property total units count
      await _firestore.collection('properties').doc(unit.propertyId).update({
        'totalUnits': FieldValue.increment(1),
      });

      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  // Get unit by ID
  Future<UnitModel?> getUnit(String unitId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('units').doc(unitId).get();
      if (!doc.exists) return null;
      return UnitModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // Get units by property
  Stream<List<UnitModel>> getUnitsByProperty(String propertyId) {
    return _firestore
        .collection('units')
        .where('propertyId', isEqualTo: propertyId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UnitModel.fromMap(doc.data()))
            .toList());
  }

  // Get units by landlord
  Stream<List<UnitModel>> getUnitsByLandlord(String landlordId) {
    return _firestore
        .collection('units')
        .where('landlordId', isEqualTo: landlordId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UnitModel.fromMap(doc.data()))
            .toList());
  }

  // Get vacant units by property
  Stream<List<UnitModel>> getVacantUnitsByProperty(String propertyId) {
    return _firestore
        .collection('units')
        .where('propertyId', isEqualTo: propertyId)
        .where('status', isEqualTo: UnitStatus.vacant.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UnitModel.fromMap(doc.data()))
            .toList());
  }

  // Update unit
  Future<bool> updateUnit(String unitId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore.collection('units').doc(unitId).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Remove tenant from unit
  Future<bool> removeTenantFromUnit(String unitId, String propertyId) async {
    try {
      await _firestore.collection('units').doc(unitId).update({
        'tenantId': null,
        'status': UnitStatus.vacant.name,
        'leaseStartDate': null,
        'leaseEndDate': null,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update property occupied units count
      await _firestore.collection('properties').doc(propertyId).update({
        'occupiedUnits': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete unit
  Future<bool> deleteUnit(String unitId, String propertyId) async {
    try {
      // Get unit to check if occupied
      UnitModel? unit = await getUnit(unitId);
      if (unit == null) return false;

      // Delete unit
      await _firestore.collection('units').doc(unitId).delete();

      // Update property counts
      Map<String, dynamic> updates = {
        'totalUnits': FieldValue.increment(-1),
      };
      if (unit.status == UnitStatus.occupied) {
        updates['occupiedUnits'] = FieldValue.increment(-1);
      }
      await _firestore.collection('properties').doc(propertyId).update(updates);

      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== DASHBOARD STATISTICS ====================

  // Get landlord dashboard stats
  Future<Map<String, dynamic>> getLandlordDashboardStats(String landlordId) async {
    try {
      // Get all properties
      QuerySnapshot propertiesSnapshot = await _firestore
          .collection('properties')
          .where('landlordId', isEqualTo: landlordId)
          .where('isActive', isEqualTo: true)
          .get();

      int totalProperties = propertiesSnapshot.docs.length;
      int totalUnits = 0;
      int occupiedUnits = 0;

      for (var doc in propertiesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalUnits += (data['totalUnits'] ?? 0) as int;
        occupiedUnits += (data['occupiedUnits'] ?? 0) as int;
      }

      // Get managers count
      QuerySnapshot managersSnapshot = await _firestore
          .collection('users')
          .where('assignedLandlordId', isEqualTo: landlordId)
          .where('role', isEqualTo: UserRole.manager.name)
          .where('isActive', isEqualTo: true)
          .get();

      // Get tenants count
      QuerySnapshot tenantsSnapshot = await _firestore
          .collection('users')
          .where('assignedLandlordId', isEqualTo: landlordId)
          .where('role', isEqualTo: UserRole.tenant.name)
          .where('isActive', isEqualTo: true)
          .get();

      return {
        'totalProperties': totalProperties,
        'totalUnits': totalUnits,
        'occupiedUnits': occupiedUnits,
        'vacantUnits': totalUnits - occupiedUnits,
        'totalManagers': managersSnapshot.docs.length,
        'totalTenants': tenantsSnapshot.docs.length,
        'occupancyRate': totalUnits > 0
            ? ((occupiedUnits / totalUnits) * 100).toStringAsFixed(1)
            : '0',
      };
    } catch (e) {
      return {
        'totalProperties': 0,
        'totalUnits': 0,
        'occupiedUnits': 0,
        'vacantUnits': 0,
        'totalManagers': 0,
        'totalTenants': 0,
        'occupancyRate': '0',
      };
    }
  }
}