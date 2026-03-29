import 'dart:convert';
import 'package:http/http.dart' as http;

class AirtelService {
  static const String _sandboxBaseUrl = 'https://openapiuat.airtel.africa';
  static const String _productionBaseUrl = 'https://openapi.airtel.africa';
  
  final bool isProduction;
  final String clientId;
  final String clientSecret;
  
  String? _accessToken;
  DateTime? _tokenExpiry;

  AirtelService({
    required this.clientId,
    required this.clientSecret,
    this.isProduction = false,
  });

  String get _baseUrl => isProduction ? _productionBaseUrl : _sandboxBaseUrl;

  Future<String?> _getAccessToken() async {
    if (_accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/oauth2/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'client_id': clientId,
          'client_secret': clientSecret,
          'grant_type': 'client_credentials',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in'] ?? 3600));
        return _accessToken;
      }
      return null;
    } catch (e) {
      print('Airtel Token Error: $e');
      return null;
    }
  }

  Future<AirtelPaymentResult> requestPayment({
    required double amount,
    required String phoneNumber,
    required String transactionId,
    String currency = 'UGX',
    String countryCode = 'UG',
  }) async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        return AirtelPaymentResult(success: false, message: 'Failed to authenticate');
      }

      final normalizedPhone = _normalizePhoneNumber(phoneNumber);

      final response = await http.post(
        Uri.parse('$_baseUrl/merchant/v1/payments/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'X-Country': countryCode,
          'X-Currency': currency,
        },
        body: jsonEncode({
          'reference': transactionId,
          'subscriber': {'country': countryCode, 'currency': currency, 'msisdn': normalizedPhone},
          'transaction': {'amount': amount.toStringAsFixed(0), 'country': countryCode, 'currency': currency, 'id': transactionId},
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['status']?['success'] == true || data['status']?['code'] == '200') {
          return AirtelPaymentResult(
            success: true,
            transactionId: transactionId,
            message: 'Payment prompt sent',
            status: AirtelPaymentStatus.pending,
          );
        }
      }
      return AirtelPaymentResult(success: false, message: 'Payment request failed');
    } catch (e) {
      return AirtelPaymentResult(success: false, message: 'Network error: $e');
    }
  }

  Future<AirtelPaymentResult> checkPaymentStatus(String transactionId) async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        return AirtelPaymentResult(success: false, message: 'Failed to authenticate');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/standard/v1/payments/$transactionId'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Country': 'UG',
          'X-Currency': 'UGX',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['data']?['transaction']?['status'];
        final isSuccess = status == 'TS';
        
        return AirtelPaymentResult(
          success: isSuccess,
          transactionId: transactionId,
          status: _parseStatus(status),
          message: isSuccess ? 'Payment successful' : 'Status: $status',
        );
      }
      return AirtelPaymentResult(success: false, message: 'Failed to check status');
    } catch (e) {
      return AirtelPaymentResult(success: false, message: 'Error: $e');
    }
  }

  String _normalizePhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('256')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('0')) cleaned = cleaned.substring(1);
    return cleaned;
  }

  AirtelPaymentStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'TS': return AirtelPaymentStatus.successful;
      case 'TF': return AirtelPaymentStatus.failed;
      case 'TIP': return AirtelPaymentStatus.pending;
      default: return AirtelPaymentStatus.unknown;
    }
  }
}

class AirtelPaymentResult {
  final bool success;
  final String? transactionId;
  final String? message;
  final AirtelPaymentStatus? status;

  AirtelPaymentResult({required this.success, this.transactionId, this.message, this.status});
}

enum AirtelPaymentStatus { pending, successful, failed, unknown }
