import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jikah/models/maintenance_model.dart';

class MaintenanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create maintenance request
  Future<String?> createMaintenanceRequest(MaintenanceModel request) async {
    try {
      final doc = await _firestore.collection('maintenance').add(request.toMap());
      return doc.id;
    } catch (e) {
      print('Error creating maintenance request: $e');
      return null;
    }
  }

  // Get maintenance by tenant - FIXED VERSION
  Stream<List<MaintenanceModel>> getMaintenanceByTenant(String tenantId) {
    return _firestore
        .collection('maintenance')
        .where('tenantId', isEqualTo: tenantId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return MaintenanceModel.fromMap(data);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Get maintenance by landlord
  Stream<List<MaintenanceModel>> getMaintenanceByLandlord(String landlordId) {
    return _firestore
        .collection('maintenance')
        .where('landlordId', isEqualTo: landlordId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return MaintenanceModel.fromMap(data);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Get maintenance by property
  Stream<List<MaintenanceModel>> getMaintenanceByProperty(String propertyId) {
    return _firestore
        .collection('maintenance')
        .where('propertyId', isEqualTo: propertyId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return MaintenanceModel.fromMap(data);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Get pending maintenance count
  Future<int> getPendingMaintenanceCount(String landlordId) async {
    try {
      final snapshot = await _firestore
          .collection('maintenance')
          .where('landlordId', isEqualTo: landlordId)
          .where('status', isEqualTo: 'pending')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Update maintenance status
  Future<bool> updateMaintenanceStatus(String requestId, MaintenanceStatus status, {String? responseNote}) async {
    try {
      final updates = <String, dynamic>{
        'status': status.toString().split('.').last,
      };
      
      if (responseNote != null) {
        updates['responseNote'] = responseNote;
      }
      
      if (status == MaintenanceStatus.fixed) {
        updates['fixedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('maintenance').doc(requestId).update(updates);
      return true;
    } catch (e) {
      return false;
    }
  }
}
