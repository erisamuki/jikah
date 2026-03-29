import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jikah/models/user_model.dart';
import 'package:jikah/models/payment_model.dart';
import 'package:jikah/models/maintenance_model.dart';
import 'package:jikah/services/currency_formatter.dart';

class SmsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Normalize Ugandan phone numbers to international format
  String _normalizeUgandanPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    
    if (!cleaned.startsWith('+256') && !cleaned.startsWith('256')) {
      cleaned = '+256$cleaned';
    } else if (cleaned.startsWith('256')) {
      cleaned = '+$cleaned';
    }
    
    return cleaned;
  }

  // ============ QUEUE SMS FOR SENDING ============
  
  Future<bool> queueSms({
    required String phoneNumber,
    required String message,
    required String type,
    String? landlordId,
    String? tenantId,
  }) async {
    try {
      String normalizedPhone = _normalizeUgandanPhone(phoneNumber);
      
      await _firestore.collection('sms_queue').add({
        'phoneNumber': normalizedPhone,
        'message': message,
        'type': type,
        'status': 'pending',
        'landlordId': landlordId,
        'tenantId': tenantId,
        'createdAt': FieldValue.serverTimestamp(),
        'attempts': 0,
      });
      
      return true;
    } catch (e) {
      print('Error queuing SMS: $e');
      return false;
    }
  }

  // ============ SEND WELCOME SMS ============
  
  Future<bool> sendWelcomeSms({
    required UserModel tenant,
    required String propertyName,
    required String unitNumber,
    String? landlordId,
  }) async {
    final message = '''Welcome to $propertyName, ${tenant.fullName.split(' ').first}! 
You have been assigned Unit $unitNumber. 
Download the Jikah app to manage your rent payments.
- Jikah Team''';
    
    return await queueSms(
      phoneNumber: tenant.phone,
      message: message,
      type: 'welcome',
      landlordId: landlordId,
      tenantId: tenant.uid,
    );
  }

  // ============ SEND PAYMENT REMINDER ============
  
  Future<bool> sendPaymentReminderSms({
    required UserModel tenant,
    required double amount,
    required DateTime dueDate,
    required String monthYear,
    String? landlordId,
  }) async {
    final message = '''Hi ${tenant.fullName.split(' ').first},
Your rent of ${CurrencyFormatter.formatUGX(amount)} for $monthYear is due on ${dueDate.day}/${dueDate.month}/${dueDate.year}. 
Please make your payment via MTN MoMo or Airtel Money.
- Jikah Team''';
    
    return await queueSms(
      phoneNumber: tenant.phone,
      message: message,
      type: 'payment_reminder',
      landlordId: landlordId,
      tenantId: tenant.uid,
    );
  }

  // ============ SEND PAYMENT CONFIRMATION ============
  
  Future<bool> sendPaymentConfirmationSms({
    required UserModel tenant,
    required PaymentModel payment,
    String? landlordId,
  }) async {
    final message = '''Payment Received!
Hi ${tenant.fullName.split(' ').first}, your rent payment of ${payment.formattedAmount} for ${payment.monthYear} has been received.
Receipt: ${payment.receiptNumber ?? 'N/A'}
Thank you!
- Jikah Team''';
    
    return await queueSms(
      phoneNumber: tenant.phone,
      message: message,
      type: 'payment_confirmation',
      landlordId: landlordId,
      tenantId: tenant.uid,
    );
  }

  // ============ SEND OVERDUE REMINDER ============
  
  Future<bool> sendOverdueReminderSms({
    required UserModel tenant,
    required double amount,
    required String monthYear,
    required int daysOverdue,
    String? landlordId,
  }) async {
    final message = '''URGENT: Hi ${tenant.fullName.split(' ').first},
Your rent of ${CurrencyFormatter.formatUGX(amount)} for $monthYear is $daysOverdue days overdue.
Please pay immediately to avoid penalties.
- Jikah Team''';
    
    return await queueSms(
      phoneNumber: tenant.phone,
      message: message,
      type: 'overdue_reminder',
      landlordId: landlordId,
      tenantId: tenant.uid,
    );
  }

  // ============ SEND MAINTENANCE UPDATE ============
  
  Future<bool> sendMaintenanceUpdateSms({
    required UserModel tenant,
    required MaintenanceModel maintenance,
    String? landlordId,
  }) async {
    String statusText;
    switch (maintenance.status) {
      case MaintenanceStatus.pending:
        statusText = 'Pending Review';
        break;
      case MaintenanceStatus.inProgress:
        statusText = 'In Progress';
        break;
      case MaintenanceStatus.fixed:
        statusText = 'Fixed/Completed';
        break;
    }
    
    final message = '''Hi ${tenant.fullName.split(' ').first},
Your maintenance request "${maintenance.title}" has been updated to: $statusText.
Check the Jikah app for details.
- Jikah Team''';
    
    return await queueSms(
      phoneNumber: tenant.phone,
      message: message,
      type: 'maintenance_update',
      landlordId: landlordId,
      tenantId: tenant.uid,
    );
  }

  // ============ SEND CUSTOM SMS ============
  
  Future<bool> sendCustomSms({
    required String phoneNumber,
    required String message,
    String? landlordId,
  }) async {
    return await queueSms(
      phoneNumber: phoneNumber,
      message: message,
      type: 'custom',
      landlordId: landlordId,
    );
  }

  // ============ GET SMS HISTORY ============
  
  Stream<List<Map<String, dynamic>>> getSmsHistory(String landlordId) {
    return _firestore
        .collection('sms_queue')
        .where('landlordId', isEqualTo: landlordId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // ============ GET SMS STATS ============
  
  Future<Map<String, int>> getSmsStats(String landlordId) async {
    try {
      final snapshot = await _firestore
          .collection('sms_queue')
          .where('landlordId', isEqualTo: landlordId)
          .get();
      
      int total = snapshot.docs.length;
      int sent = 0;
      int pending = 0;
      int failed = 0;
      
      for (final doc in snapshot.docs) {
        final status = doc.data()['status'] as String?;
        switch (status) {
          case 'sent':
            sent++;
            break;
          case 'pending':
            pending++;
            break;
          case 'failed':
            failed++;
            break;
        }
      }
      
      return {
        'total': total,
        'sent': sent,
        'pending': pending,
        'failed': failed,
      };
    } catch (e) {
      return {'total': 0, 'sent': 0, 'pending': 0, 'failed': 0};
    }
  }
}