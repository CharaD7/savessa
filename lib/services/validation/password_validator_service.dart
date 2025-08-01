import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

enum PasswordStrength {
  weak,
  medium,
  strong,
  veryStrong
}

class PasswordValidatorService {
  static final PasswordValidatorService _instance = PasswordValidatorService._internal();
  
  // Singleton pattern
  factory PasswordValidatorService() {
    return _instance;
  }
  
  PasswordValidatorService._internal();
  
  // Password policy requirements
  static const int _minLength = 8;
  static const int _minUppercase = 1;
  static const int _minLowercase = 1;
  static const int _minDigits = 1;
  static const int _minSpecialChars = 1;
  
  // Regular expressions for character types
  static final RegExp _uppercaseRegex = RegExp(r'[A-Z]');
  static final RegExp _lowercaseRegex = RegExp(r'[a-z]');
  static final RegExp _digitRegex = RegExp(r'[0-9]');
  static final RegExp _specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
  
  // Common password patterns to avoid
  static final List<RegExp> _commonPatterns = [
    RegExp(r'12345'),
    RegExp(r'qwerty', caseSensitive: false),
    RegExp(r'password', caseSensitive: false),
    RegExp(r'admin', caseSensitive: false),
    RegExp(r'welcome', caseSensitive: false),
    RegExp(r'123456789'),
    RegExp(r'987654321'),
  ];
  
  // Check if password has uppercase letters
  bool hasUppercase(String password) {
    return _uppercaseRegex.hasMatch(password);
  }
  
  // Check if password has lowercase letters
  bool hasLowercase(String password) {
    return _lowercaseRegex.hasMatch(password);
  }
  
  // Check if password has digits
  bool hasDigit(String password) {
    return _digitRegex.hasMatch(password);
  }
  
  // Check if password has special characters
  bool hasSpecialChar(String password) {
    return _specialCharRegex.hasMatch(password);
  }
  
  // Check password strength
  PasswordStrength checkStrength(String password) {
    if (password.length < _minLength) {
      return PasswordStrength.weak;
    }
    
    int score = 0;
    
    // Length score
    if (password.length >= _minLength) score++;
    if (password.length >= 10) score++;
    if (password.length >= 12) score++;
    
    // Character type score
    if (hasUppercase(password)) score++;
    if (hasLowercase(password)) score++;
    if (hasDigit(password)) score++;
    if (hasSpecialChar(password)) score++;
    
    // Variety score
    final uniqueChars = password.split('').toSet().length;
    if (uniqueChars >= password.length * 0.7) score++;
    
    // Determine strength based on score
    if (score < 4) {
      return PasswordStrength.weak;
    } else if (score < 6) {
      return PasswordStrength.medium;
    } else if (score < 8) {
      return PasswordStrength.strong;
    } else {
      return PasswordStrength.veryStrong;
    }
  }
  
  // Validate password against policy
  // Returns a tuple of (isValid, errorMessage)
  (bool, String?) validatePolicy(String password) {
    if (password.length < _minLength) {
      return (false, 'Password must be at least $_minLength characters long');
    }
    
    if (!_uppercaseRegex.hasMatch(password)) {
      return (false, 'Password must contain at least $_minUppercase uppercase letter');
    }
    
    if (!_lowercaseRegex.hasMatch(password)) {
      return (false, 'Password must contain at least $_minLowercase lowercase letter');
    }
    
    if (!_digitRegex.hasMatch(password)) {
      return (false, 'Password must contain at least $_minDigits number');
    }
    
    if (!_specialCharRegex.hasMatch(password)) {
      return (false, 'Password must contain at least $_minSpecialChars special character');
    }
    
    // Check for common patterns
    for (final pattern in _commonPatterns) {
      if (pattern.hasMatch(password)) {
        return (false, 'Password contains a common pattern that is easily guessable');
      }
    }
    
    return (true, null);
  }
  
  // Check if password has been compromised using Have I Been Pwned API
  // Uses the k-anonymity model for secure checking
  // https://haveibeenpwned.com/API/v3
  Future<(bool, String?)> checkCompromised(String password) async {
    try {
      // Generate SHA-1 hash of the password
      final bytes = utf8.encode(password);
      final digest = sha1.convert(bytes);
      final hash = digest.toString().toUpperCase();
      
      // Get the first 5 characters of the hash (prefix)
      final prefix = hash.substring(0, 5);
      final suffix = hash.substring(5);
      
      // Query the API with just the prefix
      final response = await http.get(
        Uri.parse('https://api.pwnedpasswords.com/range/$prefix'),
        headers: {'User-Agent': 'Savessa-App'},
      );
      
      if (response.statusCode == 200) {
        // Parse the response (list of hash suffixes with counts)
        final hashList = response.body.split('\r\n');
        
        // Check if our hash suffix is in the list
        for (final line in hashList) {
          final parts = line.split(':');
          if (parts.length == 2) {
            final hashSuffix = parts[0];
            final count = int.tryParse(parts[1]) ?? 0;
            
            if (hashSuffix == suffix) {
              // Password has been compromised
              return (false, 'This password has appeared in data breaches $count times');
            }
          }
        }
        
        // Password not found in breaches
        return (true, null);
      } else {
        // API error, assume password is ok for now
        print('HIBP API error: ${response.statusCode}');
        return (true, null);
      }
    } catch (e) {
      // Error occurred, assume password is ok for now
      print('HIBP check error: $e');
      return (true, null);
    }
  }
  
  // Comprehensive password validation
  // Returns a tuple of (isValid, errorMessage)
  Future<(bool, String?)> validatePassword(String password) async {
    // First check against policy
    final (isPolicyValid, policyError) = validatePolicy(password);
    if (!isPolicyValid) {
      return (false, policyError);
    }
    
    // Then check if password has been compromised
    final (isNotCompromised, compromisedError) = await checkCompromised(password);
    if (!isNotCompromised) {
      return (false, compromisedError);
    }
    
    // All checks passed
    return (true, null);
  }
  
  // Get color for password strength indicator
  Color getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.green;
      case PasswordStrength.veryStrong:
        return Colors.green.shade800;
    }
  }
  
  // Get label for password strength
  String getStrengthLabel(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }
}
