import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
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
  /// For production, this should be replaced with actual SMS provider integration
  Future<bool> sendPasswordResetSMS({
    required String phoneNumber, 
    required String resetCode
  }) async {
    try {
      final message = _buildPasswordResetSmsMessage(resetCode);
      
      // For development: use device SMS app
      if (_env.isDevelopment) {
        return await _sendViaSmsApp(phoneNumber, message);
      }
      
      // For production: integrate with actual SMS provider (Twilio, AWS SNS, etc.)
      // TODO: Replace with actual SMS provider implementation
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

  /// Sends SMS via external provider (production)
  /// TODO: Implement actual SMS provider integration
  Future<bool> _sendViaProvider(String phoneNumber, String message) async {
    try {
      // This is where you would integrate with your SMS provider
      // Examples:
      // - Twilio: https://pub.dev/packages/twilio_flutter
      // - AWS SNS: Use AWS SDK
      // - Firebase Auth SMS: Use Firebase Auth phone verification
      
      debugPrint('SMS Provider not configured. Message would be sent to $phoneNumber: $message');
      
      // For now, simulate success in development
      if (_env.isDevelopment) {
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 2));
        debugPrint('✅ SMS sent successfully (simulated)');
        return true;
      }
      
      // In production, throw error if no provider is configured
      throw Exception('SMS provider not configured');
    } catch (e) {
      debugPrint('Error sending SMS via provider: $e');
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

  /// Configuration for SMS providers (to be implemented)
  Map<String, String> get _smsProviderConfig => {
    'twilio_account_sid': _env.isDevelopment ? 'dev_account_sid' : '',
    'twilio_auth_token': _env.isDevelopment ? 'dev_auth_token' : '',
    'twilio_phone_number': _env.isDevelopment ? '+1234567890' : '',
    // Add other SMS provider configurations as needed
  };
}
