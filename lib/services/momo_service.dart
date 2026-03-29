import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class MomoService {
  static const String _sandboxBaseUrl = 'https://sandbox.momodeveloper.mtn.com';
  static const String _productionBaseUrl = 'https://proxy.momoapi.mtn.com';
  
  final bool isProduction;
  final String subscriptionKey;
  final String apiUser;
  final String apiKey;
  final String targetEnvironment;
  final String? callbackUrl;
  
  String? _accessToken;
  DateTime? _tokenExpiry;

  MomoService({
    required this.subscriptionKey,
    required this.apiUser,
    required this.apiKey,
    this.isProduction = false,
    this.callbackUrl,
  }) : targetEnvironment = isProduction ? 'mtnguganda' : 'sandbox';

  String get _baseUrl => isProduction ? _productionBaseUrl : _sandboxBaseUrl;

  Future<String?> _getAccessToken() async {
    if (_accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken;
    }

    try {
      final credentials = base64Encode(utf8.encode('$apiUser:$apiKey'));
      
      final response = await http.post(
        Uri.parse('$_baseUrl/collection/token/'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Ocp-Apim-Subscription-Key': subscriptionKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in'] ?? 3600));
        return _accessToken;
      }
      return null;
    } catch (e) {
      print('MoMo Token Error: $e');
      return null;
    }
  }

  Future<MomoPaymentResult> requestPayment({
    required double amount,
    required String phoneNumber,
    required String externalId,
    String currency = 'UGX',
    String? payerMessage,
    String? payeeNote,
  }) async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        return MomoPaymentResult(success: false, message: 'Failed to authenticate');
      }

      final referenceId = const Uuid().v4();
      final normalizedPhone = _normalizePhoneNumber(phoneNumber);

      final body = {
        'amount': amount.toStringAsFixed(0),
        'currency': currency,
        'externalId': externalId,
        'payer': {'partyIdType': 'MSISDN', 'partyId': normalizedPhone},
        'payerMessage': payerMessage ?? 'Rent Payment',
        'payeeNote': payeeNote ?? 'Jikah Rent Collection',
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/collection/v1_0/requesttopay'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Reference-Id': referenceId,
          'X-Target-Environment': targetEnvironment,
          'Ocp-Apim-Subscription-Key': subscriptionKey,
          'Content-Type': 'application/json',
          'X-Callback-Url': ?callbackUrl,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 202) {
        return MomoPaymentResult(
          success: true,
          referenceId: referenceId,
          message: 'Payment prompt sent to $normalizedPhone',
          status: PaymentRequestStatus.pending,
        );
      } else {
        return MomoPaymentResult(success: false, message: 'Payment request failed');
      }
    } catch (e) {
      return MomoPaymentResult(success: false, message: 'Network error: $e');
    }
  }

  Future<MomoPaymentResult> checkPaymentStatus(String referenceId) async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        return MomoPaymentResult(success: false, message: 'Failed to authenticate');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/collection/v1_0/requesttopay/$referenceId'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Target-Environment': targetEnvironment,
          'Ocp-Apim-Subscription-Key': subscriptionKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'] as String;
        
        return MomoPaymentResult(
          success: status == 'SUCCESSFUL',
          referenceId: referenceId,
          status: _parseStatus(status),
          message: status == 'SUCCESSFUL' ? 'Payment completed' : 'Status: $status',
          financialTransactionId: data['financialTransactionId'],
        );
      }
      return MomoPaymentResult(success: false, message: 'Failed to check status');
    } catch (e) {
      return MomoPaymentResult(success: false, message: 'Error: $e');
    }
  }

  String _normalizePhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '256${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('256')) cleaned = '256$cleaned';
    return cleaned;
  }

  PaymentRequestStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESSFUL': return PaymentRequestStatus.successful;
      case 'FAILED': return PaymentRequestStatus.failed;
      case 'PENDING': return PaymentRequestStatus.pending;
      case 'REJECTED': return PaymentRequestStatus.rejected;
      default: return PaymentRequestStatus.unknown;
    }
  }
}

class MomoPaymentResult {
  final bool success;
  final String? referenceId;
  final String? message;
  final PaymentRequestStatus? status;
  final String? financialTransactionId;

  MomoPaymentResult({
    required this.success,
    this.referenceId,
    this.message,
    this.status,
    this.financialTransactionId,
  });
}

enum PaymentRequestStatus { pending, successful, failed, rejected, unknown }
