import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:savessa/core/config/env_config.dart';

class EmailValidatorService {
  static final EmailValidatorService _instance = EmailValidatorService._internal();
  
  // Singleton pattern
  factory EmailValidatorService() {
    return _instance;
  }
  
  EmailValidatorService._internal();
  
  // Map to store verification codes
  final Map<String, String> _verificationCodes = {};
  
  // Map to store verification status
  final Map<String, bool> _verifiedEmails = {};
  
  // Comprehensive email regex pattern
  // This pattern checks for:
  // - Valid local part (before @)
  // - Valid domain part (after @)
  // - Proper TLD format
  static final RegExp _emailRegex = RegExp(
    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@'
    r'((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
    caseSensitive: false,
  );
  
  // Additional patterns for common email mistakes
  static final List<RegExp> _commonMistakePatterns = [
    RegExp(r'gmail\.co$'), // Missing 'm' in gmail.com
    RegExp(r'yahoo\.co$'), // Missing 'm' in yahoo.com
    RegExp(r'hotmail\.co$'), // Missing 'm' in hotmail.com
    RegExp(r'gmial'), // Typo in gmail
    RegExp(r'yaho\.'), // Typo in yahoo
    RegExp(r'outlok\.'), // Typo in outlook
  ];
  
  // Validate email format
  bool isValidFormat(String email) {
    if (!_emailRegex.hasMatch(email)) {
      return false;
    }
    
    // Check for common mistakes
    for (final pattern in _commonMistakePatterns) {
      if (pattern.hasMatch(email)) {
        return false;
      }
    }
    
    return true;
  }
  
  // Suggest corrections for common email mistakes
  String? suggestCorrection(String email) {
    if (_emailRegex.hasMatch(email)) {
      return null; // No correction needed
    }
    
    // Check for missing TLD
    if (email.endsWith('gmail.co')) {
      return '${email}m';
    } else if (email.endsWith('yahoo.co')) {
      return '${email}m';
    } else if (email.endsWith('hotmail.co')) {
      return '${email}m';
    }
    
    // Check for common typos
    if (email.contains('gmial')) {
      return email.replaceAll('gmial', 'gmail');
    } else if (email.contains('yaho.')) {
      return email.replaceAll('yaho.', 'yahoo.');
    } else if (email.contains('outlok.')) {
      return email.replaceAll('outlok.', 'outlook.');
    }
    
    return null;
  }
  
  // Check if email exists and is active
  // Returns a tuple of (isValid, errorMessage)
  Future<(bool, String?)> validateEmail(String email) async {
    // First check format
    if (!isValidFormat(email)) {
      final suggestion = suggestCorrection(email);
      if (suggestion != null) {
        return (false, 'Invalid email format. Did you mean $suggestion?');
      }
      return (false, 'Invalid email format');
    }
    
    try {
      // Use Abstract API for email validation
      // Free tier allows 100 requests per month
      // https://www.abstractapi.com/api/email-verification-validation-api
      final config = EnvConfig();
      final apiKey = config.abstractApiKey;
      
      // Skip API call if no API key is provided
      if (apiKey.isEmpty) {
        print('Abstract API key not found in environment variables');
        return (true, null); // Fallback to basic validation
      }
      
      final response = await http.get(
        Uri.parse('https://emailvalidation.abstractapi.com/v1/?api_key=$apiKey&email=$email'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check if email is deliverable
        final isDeliverable = data['deliverability'] == 'DELIVERABLE';
        
        // Check if email is disposable
        final isDisposable = data['is_disposable_email'] == true;
        
        // Check if the domain has proper MX records
        final hasMxRecords = data['mx_records'] == true;
        
        // Check if the email was created at least a day ago
        // Note: This is an approximation as the API doesn't provide exact creation date
        final quality = data['quality_score'] ?? 0.0;
        
        // Determine if email is valid based on all checks
        if (!isDeliverable) {
          return (false, 'Email address is not deliverable');
        }
        
        if (isDisposable) {
          return (false, 'Disposable email addresses are not allowed');
        }
        
        if (!hasMxRecords) {
          return (false, 'Email domain does not have valid mail servers');
        }
        
        if (quality < 0.7) {
          return (false, 'Email quality is too low, it may be inactive or recently created');
        }
        
        // All checks passed
        return (true, null);
      } else {
        // Fallback to basic validation if API fails
        print('Email validation API error: ${response.statusCode}');
        
        // Check domain MX records using a different approach
        final domainParts = email.split('@');
        if (domainParts.length != 2) {
          return (false, 'Invalid email format');
        }
        
        final domain = domainParts[1];
        
        // Check common domains that are known to be valid
        final commonDomains = [
          'gmail.com', 'yahoo.com', 'outlook.com', 'hotmail.com', 
          'aol.com', 'icloud.com', 'protonmail.com', 'mail.com'
        ];
        
        if (commonDomains.contains(domain.toLowerCase())) {
          return (true, null);
        }
        
        // For other domains, we'll assume they're valid if the format is correct
        // In a production app, you would want to implement a more robust fallback
        return (true, null);
      }
    } catch (e) {
      print('Email validation error: $e');
      // Fallback to basic validation if API fails
      return (true, null);
    }
  }
  
  // Check if email is already registered in the database
  // This would typically be implemented by your backend service
  Future<bool> isEmailRegistered(String email) async {
    // Simulate a database check
    await Future.delayed(const Duration(seconds: 1));
    
    // In a real app, you would check your database
    // For now, we'll just return false (not registered)
    return false;
  }
  
  // Generate a verification code for email
  String generateVerificationCode(String email) {
    final random = Random();
    final code = List.generate(6, (_) => random.nextInt(10)).join();
    _verificationCodes[email] = code;
    return code;
  }
  
  // Send verification email
  // In a real app, this would send an actual email
  // For this demo, we'll just simulate it
  Future<bool> sendVerificationEmail(String email) async {
    if (!isValidFormat(email)) {
      return false;
    }
    
    final code = generateVerificationCode(email);
    
    // Simulate sending an email
    await Future.delayed(const Duration(seconds: 1));
    
    // In a real app, you would send an actual email with the code
    print('Verification code for $email: $code');
    
    return true;
  }
  
  // Verify email with code
  bool verifyEmail(String email, String code) {
    final storedCode = _verificationCodes[email];
    if (storedCode == null) {
      return false;
    }
    
    if (storedCode == code) {
      _verifiedEmails[email] = true;
      return true;
    }
    
    return false;
  }
  
  // Check if email is verified
  bool isEmailVerified(String email) {
    return _verifiedEmails[email] ?? false;
  }
  
  // Show verification dialog
  Future<bool> showVerificationDialog(BuildContext context, String email) async {
    final codeController = TextEditingController();
    bool isVerified = false;
    
    // Send verification email
    final emailSent = await sendVerificationEmail(email);
    if (!emailSent) {
      return false;
    }
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Verify Your Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('A verification code has been sent to $email'),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  hintText: 'Enter the 6-digit code',
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final code = codeController.text;
                if (verifyEmail(email, code)) {
                  isVerified = true;
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid verification code'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
    
    return isVerified;
  }
}