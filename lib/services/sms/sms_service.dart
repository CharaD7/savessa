import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:savessa/core/config/env_config.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();
  
  final _env = EnvConfig();

  Future<bool> sendReminderSms({required String phoneNumber, required String message}) async {
    final uri = Uri(scheme: 'sms', path: phoneNumber, queryParameters: {'body': message});
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }

  /// Sends a password reset SMS with token
  Future<bool> sendPasswordResetSMS({
    required String phoneNumber, 
    required String resetCode
  }) async {
    try {
      // Validate phone number format
      if (!isValidPhoneNumber(phoneNumber)) {
        debugPrint('Invalid phone number format: $phoneNumber');
        return false;
      }
      
      final message = _buildPasswordResetSmsMessage(resetCode);
      debugPrint('Sending password reset SMS to ${formatPhoneNumber(phoneNumber)}');
      
      // Use provider-based sending (Twilio in production, SMS app in development)
      return await _sendViaProvider(phoneNumber, message);
    } catch (e) {
      debugPrint('Error sending password reset SMS: $e');
      return false;
    }
  }

  /// Sends SMS via device SMS application (development/fallback)
  Future<bool> _sendViaSmsApp(String phoneNumber, String message) async {
    try {
      final uri = Uri(scheme: 'sms', path: phoneNumber, queryParameters: {'body': message});
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error opening SMS app: $e');
      return false;
    }
  }

  /// Sends SMS via Twilio (production)
  Future<bool> _sendViaProvider(String phoneNumber, String message) async {
    try {
      // Check if Twilio is configured
      if (_env.twilioAccountSid.isEmpty || _env.twilioAuthToken.isEmpty || _env.twilioPhoneNumber.isEmpty) {
        debugPrint('Twilio not configured. Required: TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_PHONE_NUMBER');
        
        // In development, fall back to SMS app
        if (_env.isDevelopment) {
          debugPrint('Development mode: falling back to SMS app');
          return await _sendViaSmsApp(phoneNumber, message);
        }
        
        throw Exception('Twilio SMS provider not configured');
      }
      
      // Prepare Twilio API request
      final accountSid = _env.twilioAccountSid;
      final authToken = _env.twilioAuthToken;
      final fromNumber = _env.twilioPhoneNumber;
      
      // Twilio Messages API endpoint
      final url = Uri.parse('https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json');
      
      // Create authorization header (Basic Auth)
      final credentials = base64Encode(utf8.encode('$accountSid:$authToken'));
      
      // Send SMS via Twilio API
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': fromNumber,
          'To': phoneNumber,
          'Body': message,
        },
      );
      
      // Check response
      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final messageSid = responseData['sid'];
        final status = responseData['status'];
        
        debugPrint('✅ SMS sent successfully via Twilio');
        debugPrint('Message SID: $messageSid, Status: $status');
        return true;
      } else {
        // Parse error response
        final errorData = json.decode(response.body);
        final errorCode = errorData['code'];
        final errorMessage = errorData['message'];
        
        debugPrint('❌ Twilio SMS failed: $errorCode - $errorMessage');
        return false;
      }
      
    } catch (e) {
      debugPrint('Error sending SMS via Twilio: $e');
      
      // In development, try fallback to SMS app
      if (_env.isDevelopment) {
        debugPrint('Development mode: attempting SMS app fallback due to error');
        try {
          return await _sendViaSmsApp(phoneNumber, message);
        } catch (fallbackError) {
          debugPrint('SMS app fallback also failed: $fallbackError');
        }
      }
      
      return false;
    }
  }

  /// Builds the password reset SMS message
  String _buildPasswordResetSmsMessage(String resetCode) {
    return '''${_env.appName} Password Reset

Your password reset code is: $resetCode

This code expires in 10 minutes.

If you didn't request this, ignore this message.

Do not share this code with anyone.''';
  }

  /// Validates phone number format
  bool isValidPhoneNumber(String phoneNumber) {
    // Basic phone number validation
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    return phoneRegex.hasMatch(phoneNumber.replaceAll(RegExp(r'[\s-()]'), ''));
  }

  /// Formats phone number for display
  String formatPhoneNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s-()]'), '');
    if (cleanNumber.length >= 10) {
      // Simple US format: +1 (555) 123-4567
      if (cleanNumber.startsWith('+1') && cleanNumber.length == 12) {
        return '+1 (${cleanNumber.substring(2, 5)}) ${cleanNumber.substring(5, 8)}-${cleanNumber.substring(8)}';
      }
      // International format: show first 3 and last 4 digits
      if (cleanNumber.length > 6) {
        final masked = '*' * (cleanNumber.length - 7);
        return '${cleanNumber.substring(0, 3)}$masked${cleanNumber.substring(cleanNumber.length - 4)}';
      }
    }
    return phoneNumber;
  }

  /// Checks if Twilio is properly configured
  bool isTwilioConfigured() {
    return _env.twilioAccountSid.isNotEmpty && 
           _env.twilioAuthToken.isNotEmpty && 
           _env.twilioPhoneNumber.isNotEmpty;
  }
  
  /// Gets Twilio configuration status for debugging
  Map<String, dynamic> getTwilioStatus() {
    return {
      'configured': isTwilioConfigured(),
      'account_sid_set': _env.twilioAccountSid.isNotEmpty,
      'auth_token_set': _env.twilioAuthToken.isNotEmpty,
      'phone_number_set': _env.twilioPhoneNumber.isNotEmpty,
      'phone_number': _env.twilioPhoneNumber.isNotEmpty ? 
        formatPhoneNumber(_env.twilioPhoneNumber) : 'Not set',
      'environment': _env.appEnv,
    };
  }
  
  /// Tests Twilio connectivity (optional, for debugging)
  Future<Map<String, dynamic>> testTwilioConnection() async {
    final status = {
      'success': false,
      'message': '',
      'details': <String, dynamic>{},
    };
    
    try {
      if (!isTwilioConfigured()) {
        status['message'] = 'Twilio not properly configured';
        status['details'] = getTwilioStatus();
        return status;
      }
      
      // Test by fetching account information
      final accountSid = _env.twilioAccountSid;
      final authToken = _env.twilioAuthToken;
      final credentials = base64Encode(utf8.encode('$accountSid:$authToken'));
      final url = Uri.parse('https://api.twilio.com/2010-04-01/Accounts/$accountSid.json');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        status['success'] = true;
        status['message'] = 'Twilio connection successful';
        status['details'] = {
          'account_sid': data['sid'],
          'friendly_name': data['friendly_name'],
          'status': data['status'],
        };
      } else {
        status['message'] = 'Twilio authentication failed';
        status['details'] = {
          'status_code': response.statusCode,
          'response': response.body,
        };
      }
    } catch (e) {
      status['message'] = 'Twilio connection test failed';
      status['details'] = {'error': e.toString()};
    }
    
    return status;
  }
}
