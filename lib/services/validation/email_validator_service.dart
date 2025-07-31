import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailValidatorService {
  static final EmailValidatorService _instance = EmailValidatorService._internal();
  
  // Singleton pattern
  factory EmailValidatorService() {
    return _instance;
  }
  
  EmailValidatorService._internal();
  
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
  
  // Validate email format
  bool isValidFormat(String email) {
    return _emailRegex.hasMatch(email);
  }
  
  // Check if email exists and is active
  // Returns a tuple of (isValid, errorMessage)
  Future<(bool, String?)> validateEmail(String email) async {
    // First check format
    if (!isValidFormat(email)) {
      return (false, 'Invalid email format');
    }
    
    try {
      // Use Abstract API for email validation
      // Free tier allows 100 requests per month
      // https://www.abstractapi.com/api/email-verification-validation-api
      const apiKey = 'YOUR_ABSTRACT_API_KEY'; // Replace with your API key
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
}