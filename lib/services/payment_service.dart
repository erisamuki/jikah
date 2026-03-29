import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jikah/models/payment_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create payment
  Future<String?> createPayment(PaymentModel payment) async {
    try {
      final doc = await _firestore.collection('payments').add(payment.toMap());
      return doc.id;
    } catch (e) {
      print('Error creating payment: $e');
      return null;
    }
  }

  // Get payments by tenant - FIXED VERSION
  Stream<List<PaymentModel>> getPaymentsByTenant(String tenantId) {
    return _firestore
        .collection('payments')
        .where('tenantId', isEqualTo: tenantId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PaymentModel.fromMap(data);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Get payments by landlord
  Stream<List<PaymentModel>> getPaymentsByLandlord(String landlordId) {
    return _firestore
        .collection('payments')
        .where('landlordId', isEqualTo: landlordId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PaymentModel.fromMap(data);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Get recent payments
  Stream<List<PaymentModel>> getRecentPayments(String landlordId, {int limit = 5}) {
    return _firestore
        .collection('payments')
        .where('landlordId', isEqualTo: landlordId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PaymentModel.fromMap(data);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list.take(limit).toList();
    });
  }

  // Get payment stats
  Future<Map<String, int>> getPaymentStats(String landlordId) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('landlordId', isEqualTo: landlordId)
          .get();

      int paid = 0;
      int pending = 0;
      int overdue = 0;

      for (final doc in snapshot.docs) {
        final status = doc.data()['status'] as String?;
        switch (status) {
          case 'paid':
            paid++;
            break;
          case 'pending':
            pending++;
            break;
          case 'overdue':
            overdue++;
            break;
        }
      }

      return {'paid': paid, 'pending': pending, 'overdue': overdue};
    } catch (e) {
      return {'paid': 0, 'pending': 0, 'overdue': 0};
    }
  }

  // Update payment status
  Future<bool> updatePaymentStatus(String paymentId, PaymentStatus status) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': status.toString().split('.').last,
        'paidDate': status == PaymentStatus.paid ? FieldValue.serverTimestamp() : null,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
