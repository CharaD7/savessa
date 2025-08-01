import 'package:intl_phone_field/countries.dart';

/// A service for validating phone numbers with country-specific rules
class PhoneValidatorService {
  /// Map of country codes to invalid leading digits
  static final Map<String, List<String>> _invalidLeadingDigits = {
    'GH': ['0', '1', '4', '6', '7', '8', '9'], // Ghana
    'US': ['0', '1'], // United States
    'GB': ['0'], // United Kingdom
    'NG': ['0'], // Nigeria
    'ZA': ['0'], // South Africa
    'FR': ['0'], // France
    'DE': ['0'], // Germany
    'CA': ['0', '1'], // Canada
    'AU': ['0'], // Australia
    'IN': ['0'], // India
    'CN': ['0'], // China
    'JP': ['0'], // Japan
    'BR': ['0'], // Brazil
    'MX': ['0'], // Mexico
    'ES': ['0'], // Spain
    'IT': ['0'], // Italy
    // Add more countries as needed
  };

  /// Map of country codes to expected phone number lengths
  static final Map<String, List<int>> _expectedLengths = {
    'GH': [9], // Ghana
    'US': [10], // United States
    'GB': [10, 11], // United Kingdom
    'NG': [10], // Nigeria
    'ZA': [9], // South Africa
    'FR': [9], // France
    'DE': [10, 11], // Germany
    'CA': [10], // Canada
    'AU': [9], // Australia
    'IN': [10], // India
    'CN': [11], // China
    'JP': [10], // Japan
    'BR': [10, 11], // Brazil
    'MX': [10], // Mexico
    'ES': [9], // Spain
    'IT': [9, 10], // Italy
    // Add more countries as needed
  };

  /// Gets the expected length for a country code
  /// Returns a list of valid lengths, or a default list if not found
  static List<int> getExpectedLength(String countryCode) {
    return _expectedLengths[countryCode] ?? [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
  }
  
  /// Gets the minimum expected length for a country code
  /// Returns the first (usually minimum) valid length
  static int getMinExpectedLength(String countryCode) {
    final lengths = getExpectedLength(countryCode);
    return lengths.first;
  }
  
  /// Gets the maximum expected length for a country code
  /// Returns the last (usually maximum) valid length
  static int getMaxExpectedLength(String countryCode) {
    final lengths = getExpectedLength(countryCode);
    return lengths.last;
  }

  /// Validates a phone number from IntlPhoneField
  static String? validateIntlPhone(dynamic phone, Country country) {
    if (phone == null || phone.number.isEmpty) {
      return 'Phone number is required';
    }
    
    final phoneNumber = phone.number;
    final countryCode = country.code;
    
    // Check if phone number contains only digits
    if (!RegExp(r'^\d+$').hasMatch(phoneNumber)) {
      return 'Phone number must contain only digits';
    }
    
    // Check for invalid leading digits
    if (phoneNumber.isNotEmpty) {
      final firstDigit = phoneNumber[0];
      final invalidDigits = _invalidLeadingDigits[countryCode] ?? ['0'];
      
      if (invalidDigits.contains(firstDigit)) {
        return 'Invalid number for ${country.name}. Cannot start with $firstDigit';
      }
    }
    
    // Check for expected length
    final validLengths = _expectedLengths[countryCode] ?? [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
    
    if (!validLengths.contains(phoneNumber.length)) {
      if (validLengths.length == 1) {
        return '${country.name} phone numbers must be ${validLengths[0]} digits';
      } else {
        return '${country.name} phone numbers must be between ${validLengths.first} and ${validLengths.last} digits';
      }
    }
    
    // All checks passed
    return null;
  }
}