import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jikah/services/momo_service.dart';
import 'package:jikah/services/airtel_service.dart';

class PaymentGatewayService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final MomoService _momoService;
  late final AirtelService _airtelService;
  
  PaymentGatewayService({
    String momoSubscriptionKey = 'YOUR_MOMO_SUBSCRIPTION_KEY',
    String momoApiUser = 'YOUR_MOMO_API_USER',
    String momoApiKey = 'YOUR_MOMO_API_KEY',
    String airtelClientId = 'YOUR_AIRTEL_CLIENT_ID',
    String airtelClientSecret = 'YOUR_AIRTEL_CLIENT_SECRET',
    bool isProduction = false,
  }) {
    _momoService = MomoService(
      subscriptionKey: momoSubscriptionKey,
      apiUser: momoApiUser,
      apiKey: momoApiKey,
      isProduction: isProduction,
    );
    _airtelService = AirtelService(
      clientId: airtelClientId,
      clientSecret: airtelClientSecret,
      isProduction: isProduction,
    );
  }

  Future<PaymentResult> payWithMTNMomo({
    required String tenantId,
    required String landlordId,
    required String propertyId,
    required String unitId,
    required double amount,
    required String phoneNumber,
    required String monthYear,
  }) async {
    final transactionId = 'JIKAH-${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      final paymentRef = await _createPendingPayment(
        tenantId: tenantId, landlordId: landlordId, propertyId: propertyId,
        unitId: unitId, amount: amount, method: 'mtnMomo',
        transactionId: transactionId, monthYear: monthYear,
      );

      final result = await _momoService.requestPayment(
        amount: amount,
        phoneNumber: phoneNumber,
        externalId: transactionId,
        payerMessage: 'Rent payment for $monthYear',
      );

      if (result.success && result.referenceId != null) {
        await _firestore.collection('payments').doc(paymentRef).update({
          'providerReferenceId': result.referenceId,
        });
        return PaymentResult(
          success: true,
          paymentId: paymentRef,
          transactionId: transactionId,
          referenceId: result.referenceId,
          message: 'Payment prompt sent! Enter your MTN MoMo PIN.',
          requiresVerification: true,
        );
      } else {
        await _firestore.collection('payments').doc(paymentRef).update({'status': 'failed'});
        return PaymentResult(success: false, message: result.message ?? 'Failed');
      }
    } catch (e) {
      return PaymentResult(success: false, message: 'Error: $e');
    }
  }

  Future<PaymentResult> payWithAirtelMoney({
    required String tenantId,
    required String landlordId,
    required String propertyId,
    required String unitId,
    required double amount,
    required String phoneNumber,
    required String monthYear,
  }) async {
    final transactionId = 'JIKAH-${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      final paymentRef = await _createPendingPayment(
        tenantId: tenantId, landlordId: landlordId, propertyId: propertyId,
        unitId: unitId, amount: amount, method: 'airtelMoney',
        transactionId: transactionId, monthYear: monthYear,
      );

      final result = await _airtelService.requestPayment(
        amount: amount,
        phoneNumber: phoneNumber,
        transactionId: transactionId,
      );

      if (result.success) {
        return PaymentResult(
          success: true,
          paymentId: paymentRef,
          transactionId: transactionId,
          message: 'Payment prompt sent! Enter your Airtel Money PIN.',
          requiresVerification: true,
        );
      } else {
        await _firestore.collection('payments').doc(paymentRef).update({'status': 'failed'});
        return PaymentResult(success: false, message: result.message ?? 'Failed');
      }
    } catch (e) {
      return PaymentResult(success: false, message: 'Error: $e');
    }
  }

  Future<PaymentResult> verifyMomoPayment(String paymentId, String referenceId) async {
    try {
      final result = await _momoService.checkPaymentStatus(referenceId);
      
      if (result.status == PaymentRequestStatus.successful) {
        await _firestore.collection('payments').doc(paymentId).update({
          'status': 'paid',
          'paidDate': FieldValue.serverTimestamp(),
        });
        return PaymentResult(success: true, message: 'Payment verified!');
      } else if (result.status == PaymentRequestStatus.pending) {
        return PaymentResult(success: false, message: 'Still pending...', requiresVerification: true);
      } else {
        await _firestore.collection('payments').doc(paymentId).update({'status': 'failed'});
        return PaymentResult(success: false, message: 'Payment failed');
      }
    } catch (e) {
      return PaymentResult(success: false, message: 'Error: $e');
    }
  }

  Future<String> _createPendingPayment({
    required String tenantId,
    required String landlordId,
    required String propertyId,
    required String unitId,
    required double amount,
    required String method,
    required String transactionId,
    required String monthYear,
  }) async {
    final doc = await _firestore.collection('payments').add({
      'tenantId': tenantId,
      'landlordId': landlordId,
      'propertyId': propertyId,
      'unitId': unitId,
      'amount': amount,
      'status': 'pending',
      'method': method,
      'transactionId': transactionId,
      'receiptNumber': 'RCP${DateTime.now().millisecondsSinceEpoch}',
      'monthYear': monthYear,
      'dueDate': Timestamp.now(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }
}

class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? transactionId;
  final String? referenceId;
  final String? message;
  final bool requiresVerification;

  PaymentResult({
    required this.success,
    this.paymentId,
    this.transactionId,
    this.referenceId,
    this.message,
    this.requiresVerification = false,
  });
}
