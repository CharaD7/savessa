import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/validated_text_field.dart';
import '../../../../shared/widgets/password_strength_indicator.dart';
import '../../../../shared/widgets/phone_number_count_indicator.dart';
import '../../../../services/database/database_service.dart';
import '../../../../services/validation/email_validator_service.dart';
import '../../../../services/validation/password_validator_service.dart';
import '../../../../services/validation/phone_validator_service.dart';
import '../../../../core/constants/icon_mapping.dart';
import '../../../../core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  final String? selectedRole;
  
  const RegisterScreen({
    super.key, 
    this.selectedRole,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _otherNamesController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _selectedRole = 'member'; // Default role
  
  // Phone field variables
  String _countryCode = '+1'; // Default country code (US)
  String _completePhoneNumber = ''; // Complete phone number with country code
  Country _selectedCountry = countries.firstWhere((country) => country.code == 'US'); // Default country
  int _phoneDigitCount = 0; // Current number of digits in phone number
  int _requiredPhoneDigits = 10; // Required number of digits for selected country (default to US)
  bool _isPhoneMaxReached = false; // Whether the maximum digit count has been reached
  
  // Validation status tracking
  ValidationStatus _emailValidationStatus = ValidationStatus.none;
  ValidationStatus _confirmEmailValidationStatus = ValidationStatus.none;
  ValidationStatus _passwordValidationStatus = ValidationStatus.none;
  ValidationStatus _confirmPasswordValidationStatus = ValidationStatus.none;
  ValidationStatus _phoneValidationStatus = ValidationStatus.none;
  
  // Focus nodes to control field focus
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _otherNamesFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _confirmEmailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  
  // Voice guidance and animation
  bool _voiceGuidanceEnabled = false;
  String _currentField = '';
  late AnimationController _animationController;
  
  // Method to get the device's locale and map it to a country code
  String _getDeviceLocale() {
    try {
      // Get the device's locale
      final String localeName = Platform.localeName;
      debugPrint('Device locale: $localeName');
      
      // Parse the locale to extract the country code
      // Locale format is typically 'language_COUNTRY' (e.g., 'en_US')
      final List<String> localeParts = localeName.split('_');
      if (localeParts.length > 1) {
        final String countryCode = localeParts[1];
        
        // Check if this country code exists in our countries list
        try {
          final bool countryExists = countries.any(
            (c) => c.code.toLowerCase() == countryCode.toLowerCase()
          );
          
          if (countryExists) {
            debugPrint('Found country from device locale: $countryCode');
            return countryCode;
          }
        } catch (e) {
          debugPrint('Error checking country from locale: $e');
        }
      }
    } catch (e) {
      debugPrint('Error getting device locale: $e');
    }
    
    // Return a default country code if we couldn't get a valid one from the locale
    return 'US';
  }

  // Method to get the current location and set the country
  Future<void> _detectUserCountry() async {
    // First try to get the country from device settings
    final String deviceCountryCode = _getDeviceLocale();
    
    // Try to find the country in the countries list
    try {
      final Country country = countries.firstWhere(
        (c) => c.code.toLowerCase() == deviceCountryCode.toLowerCase(),
        orElse: () => countries.firstWhere((c) => c.code == 'US'), // Default to US if not found
      );
      
      // Update the selected country
      setState(() {
        _selectedCountry = country;
        _countryCode = '+${country.dialCode}';
      });
      
      debugPrint('Set country from device settings: ${country.name} (${country.code})');
      return; // Exit early if we successfully set the country from device settings
    } catch (e) {
      debugPrint('Error finding country from device settings: $e');
      // Continue to geolocation fallback
    }
    
    // Fallback to geolocation if device settings didn't provide a valid country
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied, use default country
          debugPrint('Location permissions are denied, using default country');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        // Permissions are permanently denied, use default country
        debugPrint('Location permissions are permanently denied, using default country');
        return;
      }
      
      // Get current position
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // Low accuracy is sufficient for country detection
        timeLimit: const Duration(seconds: 5), // Timeout after 5 seconds
      );
      
      // Use the position to determine the country
      // This is a simplified approach - in a real app, you would use a geocoding service
      // For now, we'll use a simple mapping of coordinates to country codes
      final String countryCode = await _getCountryFromCoordinates(position.latitude, position.longitude);
      
      // Find the country in the countries list
      try {
        final Country country = countries.firstWhere(
          (c) => c.code.toLowerCase() == countryCode.toLowerCase(),
          orElse: () => countries.firstWhere((c) => c.code == 'US'), // Default to US if not found
        );
        
        // Update the selected country
        setState(() {
          _selectedCountry = country;
          _countryCode = '+${country.dialCode}';
        });
        
        debugPrint('Detected country: ${country.name} (${country.code})');
      } catch (e) {
        debugPrint('Error finding country: $e');
      }
    } catch (e) {
      debugPrint('Error detecting user country: $e');
    }
  }
  
  // Method to get country code from coordinates
  // This is a simplified approach - in a real app, you would use a geocoding service
  Future<String> _getCountryFromCoordinates(double latitude, double longitude) async {
    // For demonstration purposes, we'll use a very simplified approach
    // In a real app, you would use a geocoding service like Google Maps Geocoding API
    
    // North America (roughly)
    if (latitude > 15 && latitude < 70 && longitude > -170 && longitude < -50) {
      if (latitude > 25 && latitude < 50 && longitude > -125 && longitude < -65) {
        return 'US'; // United States
      } else if (latitude > 45 && latitude < 70 && longitude > -140 && longitude < -50) {
        return 'CA'; // Canada
      } else if (latitude > 15 && latitude < 32 && longitude > -120 && longitude < -85) {
        return 'MX'; // Mexico
      }
    }
    
    // Europe (roughly)
    if (latitude > 35 && latitude < 70 && longitude > -10 && longitude < 40) {
      if (latitude > 48 && latitude < 55 && longitude > -10 && longitude < 2) {
        return 'GB'; // United Kingdom
      } else if (latitude > 42 && latitude < 51 && longitude > -5 && longitude < 10) {
        return 'FR'; // France
      } else if (latitude > 47 && latitude < 55 && longitude > 5 && longitude < 15) {
        return 'DE'; // Germany
      }
    }
    
    // Africa (roughly)
    if (latitude > -35 && latitude < 35 && longitude > -20 && longitude < 50) {
      if (latitude > 4 && latitude < 12 && longitude > -5 && longitude < 4) {
        return 'GH'; // Ghana
      } else if (latitude > 25 && latitude < 32 && longitude > 25 && longitude < 35) {
        return 'EG'; // Egypt
      } else if (latitude > -35 && latitude < -22 && longitude > 15 && longitude < 35) {
        return 'ZA'; // South Africa
      }
    }
    
    // Asia (roughly)
    if (latitude > 0 && latitude < 70 && longitude > 60 && longitude < 180) {
      if (latitude > 20 && latitude < 40 && longitude > 70 && longitude < 135) {
        return 'CN'; // China
      } else if (latitude > 20 && latitude < 45 && longitude > 125 && longitude < 150) {
        return 'JP'; // Japan
      } else if (latitude > 5 && latitude < 20 && longitude > 95 && longitude < 105) {
        return 'TH'; // Thailand
      }
    }
    
    // Default to US if we can't determine the country
    return 'US';
  }

  @override
  void initState() {
    super.initState();
    
    // Set system UI to be transparent for fullscreen effect
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Set selected role from widget parameter if provided
    if (widget.selectedRole != null) {
      _selectedRole = widget.selectedRole!;
    }
    
    // Detect user's country
    _detectUserCountry();
    
    // Initialize required phone digits based on default country
    _requiredPhoneDigits = PhoneValidatorService.getMaxExpectedLength(_selectedCountry.code);
    
    // Add listeners to focus nodes
    _firstNameFocusNode.addListener(() {
      if (_firstNameFocusNode.hasFocus) {
        setState(() {
          _currentField = 'firstName';
        });
        if (_voiceGuidanceEnabled) {
          _playFieldGuidance('firstName');
        }
      }
    });
    
    _lastNameFocusNode.addListener(() {
      if (_lastNameFocusNode.hasFocus) {
        setState(() {
          _currentField = 'lastName';
        });
        if (_voiceGuidanceEnabled) {
          _playFieldGuidance('lastName');
        }
      }
    });
    
    _otherNamesFocusNode.addListener(() {
      if (_otherNamesFocusNode.hasFocus) {
        setState(() {
          _currentField = 'otherNames';
        });
        if (_voiceGuidanceEnabled) {
          _playFieldGuidance('otherNames');
        }
      }
    });
    
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        setState(() {
          _currentField = 'email';
        });
        if (_voiceGuidanceEnabled) {
          _playFieldGuidance('email');
        }
      }
    });
    
    _confirmEmailFocusNode.addListener(() {
      if (_confirmEmailFocusNode.hasFocus) {
        setState(() {
          _currentField = 'confirmEmail';
        });
        if (_voiceGuidanceEnabled) {
          _playFieldGuidance('confirmEmail');
        }
      }
    });
    
    _phoneFocusNode.addListener(() {
      if (_phoneFocusNode.hasFocus) {
        setState(() {
          _currentField = 'phone';
        });
        if (_voiceGuidanceEnabled) {
          _playFieldGuidance('phone');
        }
      }
    });
    
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        setState(() {
          _currentField = 'password';
        });
        if (_voiceGuidanceEnabled) {
          _playFieldGuidance('password');
        }
      }
    });
    
    _confirmPasswordFocusNode.addListener(() {
      if (_confirmPasswordFocusNode.hasFocus) {
        setState(() {
          _currentField = 'confirmPassword';
        });
        if (_voiceGuidanceEnabled) {
          _playFieldGuidance('confirmPassword');
        }
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _otherNamesController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    
    // Dispose focus nodes
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _otherNamesFocusNode.dispose();
    _emailFocusNode.dispose();
    _confirmEmailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    
    // Dispose animation controller
    _animationController.dispose();
    
    super.dispose();
  }
  
  // Play field guidance audio (to be implemented with actual sound assets)
  void _playFieldGuidance(String field) {
    // TODO: Implement audio playback when assets are available
    debugPrint('Playing guidance for $field field');
  }
  
  // Toggle voice guidance
  void _toggleVoiceGuidance() {
    setState(() {
      _voiceGuidanceEnabled = !_voiceGuidanceEnabled;
    });
    
    if (_voiceGuidanceEnabled && _currentField.isNotEmpty) {
      _playFieldGuidance(_currentField);
    }
  }

  void _register() async {
    // First check if the form is valid using standard validation
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Then check if all fields with async validation are valid
    if (_emailValidationStatus != ValidationStatus.valid) {
      // Trigger email validation if not already valid
      _emailFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please ensure your email is valid before continuing.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    
    if (_confirmEmailValidationStatus != ValidationStatus.valid) {
      // Trigger confirm email validation if not already valid
      _confirmEmailFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please ensure your email confirmation matches.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    
    if (_passwordValidationStatus != ValidationStatus.valid) {
      // Trigger password validation if not already valid
      _passwordFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please ensure your password meets all requirements.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    
    if (_confirmPasswordValidationStatus != ValidationStatus.valid) {
      // Trigger confirm password validation if not already valid
      _confirmPasswordFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please ensure your password confirmation matches.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Verify email before proceeding
    final emailValidator = EmailValidatorService();
    final email = _emailController.text.trim();
    
    // Check if email is already verified
    if (!emailValidator.isEmailVerified(email)) {
      // Show verification dialog
      final isVerified = await emailValidator.showVerificationDialog(context, email);
      
      if (!isVerified) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Email verification is required to register.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Collect user data
      final userData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'other_names': _otherNamesController.text.trim(),
        'email': email,
        'phone': _completePhoneNumber, // Use complete phone number with country code
        'country_code': _countryCode, // Store country code separately
        'phone_country': _selectedCountry.code.toString(), // Store country code (e.g., 'US', 'GH')
        'role': _selectedRole,
        'password': _passwordController.text, // In a real app, this would be hashed
        'email_verified': true, // Mark as verified since we've verified it
      };
      
      // Use the DatabaseService to create a new user
      final dbService = DatabaseService();
      
      // Check if user with this email already exists
      // This is a double-check since we already validated the email
      final existingUser = await dbService.getUserByEmail(email);
      if (existingUser != null) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Email already registered. Please use a different email.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
      
      // Create the user in the database
      await dbService.createUser(userData);
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.register_success'.tr()),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to login screen with selected role
      context.go('/login', extra: _selectedRole);
    } catch (e) {
      if (!mounted) return;
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.royalPurple,
              AppTheme.lightPurple,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.0, statusBarHeight + 24.0, 24.0, 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App logo with drop shadow
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'S',
                      style: TextStyle(
                        color: theme.colorScheme.onSecondary,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Header with glassmorphism effect
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Create Account',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.selectedRole == 'admin' 
                            ? 'Setting up as Savings Manager' 
                            : 'Setting up as Savings Contributor',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary.withOpacity(0.9),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Login/Register toggle - Link to login
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'auth.have_account'.tr(),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.go('/login', extra: _selectedRole);
                        },
                        child: Text(
                          'auth.sign_in'.tr(),
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Voice guidance toggle with improved styling
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        IconMapping.settings,
                        color: theme.colorScheme.onPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Voice Guidance',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _voiceGuidanceEnabled,
                        onChanged: (value) {
                          _toggleVoiceGuidance();
                        },
                        activeColor: theme.colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
                  
                const SizedBox(height: 32),
                
                // Form with glassmorphism container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        
                        // First name field
                        AppTextField(
                          label: 'auth.first_name'.tr(),
                          controller: _firstNameController,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(IconMapping.person),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'errors.required_field'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Last name field
                        AppTextField(
                          label: 'auth.last_name'.tr(),
                          controller: _lastNameController,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(IconMapping.personOutline),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'errors.required_field'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Other names field
                        AppTextField(
                          label: 'auth.other_names'.tr(),
                          controller: _otherNamesController,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(IconMapping.peopleOutline),
                          // Other names is optional, so no validator
                        ),
                        const SizedBox(height: 16),
                        
                        // Email field
                        ValidatedTextField(
                          label: 'auth.email'.tr(),
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(IconMapping.email),
                          required: true,
                          showValidationStatus: true,
                          preventNextIfInvalid: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'errors.required_field'.tr();
                            }
                            
                            final emailValidator = EmailValidatorService();
                            if (!emailValidator.isValidFormat(value)) {
                              // Check if we can suggest a correction
                              final suggestion = emailValidator.suggestCorrection(value);
                              if (suggestion != null) {
                                return 'Invalid email format. Did you mean $suggestion?';
                              }
                              return 'errors.invalid_email'.tr();
                            }
                            
                            return null;
                          },
                          asyncValidator: (value) async {
                            final emailValidator = EmailValidatorService();
                            
                            // First check if email is already registered
                            final isRegistered = await emailValidator.isEmailRegistered(value);
                            if (isRegistered) {
                              return (false, 'Email already registered. Please use a different email.');
                            }
                            
                            // Then validate email existence and activity
                            return await emailValidator.validateEmail(value);
                          },
                          onChanged: (value) {
                            // Reset validation status when text changes
                            setState(() {
                              _emailValidationStatus = ValidationStatus.none;
                            });
                          },
                          onValidationComplete: (status) {
                            // Update validation status when validation completes
                            setState(() {
                              _emailValidationStatus = status;
                              
                              // If valid, move to next field
                              if (_emailValidationStatus == ValidationStatus.valid) {
                                _confirmEmailFocusNode.requestFocus();
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Confirm Email field
                        ValidatedTextField(
                          label: 'Confirm Email',
                          controller: _confirmEmailController,
                          focusNode: _confirmEmailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(IconMapping.email),
                          required: true,
                          showValidationStatus: true,
                          preventNextIfInvalid: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'errors.required_field'.tr();
                            }
                            if (value != _emailController.text) {
                              return 'Email addresses do not match';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            // Update validation status based on whether emails match
                            setState(() {
                              if (value.isEmpty) {
                                _confirmEmailValidationStatus = ValidationStatus.none;
                              } else if (value == _emailController.text) {
                                _confirmEmailValidationStatus = ValidationStatus.valid;
                              } else {
                                _confirmEmailValidationStatus = ValidationStatus.invalid;
                              }
                            });
                          },
                          onValidationComplete: (status) {
                            setState(() {
                              _confirmEmailValidationStatus = status;
                              
                              // If valid, move to next field
                              if (_confirmEmailValidationStatus == ValidationStatus.valid) {
                                _phoneFocusNode.requestFocus();
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Phone field with country selector
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                                  child: Text(
                                    'auth.phone'.tr(),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 4, bottom: 8),
                                  child: PhoneNumberCountIndicator(
                                    currentCount: _phoneDigitCount,
                                    requiredCount: _requiredPhoneDigits,
                                    isMaxReached: _isPhoneMaxReached,
                                  ),
                                ),
                              ],
                            ),
                            IntlPhoneField(
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                              decoration: InputDecoration(
                                hintText: 'Enter phone number',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.gold, width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red, width: 2),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red, width: 2),
                                ),
                              ),
                              initialCountryCode: _selectedCountry.code,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              dropdownTextStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              dropdownIcon: const Icon(
                                IconMapping.search,
                                color: Colors.white,
                                size: 18,
                              ),
                              flagsButtonPadding: const EdgeInsets.symmetric(horizontal: 8),
                              showDropdownIcon: false,
                              disableLengthCheck: false,
                              invalidNumberMessage: 'errors.invalid_phone'.tr(),
                              onChanged: (phone) {
                                // Get the current text from the controller
                                final currentText = phone.number;
                                
                                // Check if we need to restrict input (max reached and trying to add more)
                                if (_isPhoneMaxReached && currentText.length > _phoneDigitCount) {
                                  // User is trying to add more digits after max is reached
                                  // Revert to previous text by removing the last character
                                  final restrictedText = currentText.substring(0, _phoneDigitCount);
                                  
                                  // Update the controller with the restricted text
                                  // We need to use Future.microtask to avoid setState during build
                                  Future.microtask(() {
                                    // Set the selection to the end of the text
                                    final selection = TextSelection.collapsed(offset: restrictedText.length);
                                    
                                    // Update the controller
                                    _phoneController.value = TextEditingValue(
                                      text: restrictedText,
                                      selection: selection,
                                    );
                                  });
                                  
                                  // Show a message to the user
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Maximum digit count reached (${_requiredPhoneDigits})'),
                                      duration: const Duration(seconds: 1),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  
                                  return; // Don't update state
                                }
                                
                                setState(() {
                                  _countryCode = phone.countryCode;
                                  _completePhoneNumber = phone.completeNumber;
                                  
                                  // Update digit count
                                  _phoneDigitCount = currentText.length;
                                  
                                  // Check if max reached
                                  _isPhoneMaxReached = _phoneDigitCount >= _requiredPhoneDigits;
                                  
                                  // Update validation status
                                  _phoneValidationStatus = ValidationStatus.valid;
                                });
                              },
                              onCountryChanged: (country) {
                                setState(() {
                                  _countryCode = '+${country.dialCode}';
                                  _selectedCountry = country;
                                  
                                  // Get the required digit count for this country using the helper method
                                  _requiredPhoneDigits = PhoneValidatorService.getMaxExpectedLength(country.code);
                                  
                                  // Reset max reached flag when country changes
                                  _isPhoneMaxReached = false;
                                  
                                  // Update complete phone number
                                  if (_phoneController.text.isNotEmpty) {
                                    _completePhoneNumber = '$_countryCode${_phoneController.text}';
                                    
                                    // Update digit count and check if max reached
                                    _phoneDigitCount = _phoneController.text.length;
                                    _isPhoneMaxReached = _phoneDigitCount >= _requiredPhoneDigits;
                                  } else {
                                    _phoneDigitCount = 0;
                                  }
                                });
                              },
                              validator: (phone) {
                                // Use the static method from PhoneValidatorService
                                final errorMessage = PhoneValidatorService.validateIntlPhone(phone, _selectedCountry);
                                
                                // Update validation status based on result
                                setState(() {
                                  _phoneValidationStatus = errorMessage == null 
                                      ? ValidationStatus.valid 
                                      : ValidationStatus.invalid;
                                });
                                
                                return errorMessage;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Role indication (simplified)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                IconMapping.person,
                                color: theme.colorScheme.secondary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedRole == 'admin'
                                      ? 'Setting up as Savings Manager'
                                      : 'Setting up as Savings Contributor',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Password field
                        ValidatedTextField(
                          label: 'auth.password'.tr(),
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(IconMapping.lock),
                          required: true,
                          showValidationStatus: true,
                          preventNextIfInvalid: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'errors.required_field'.tr();
                            }
                            
                            final passwordValidator = PasswordValidatorService();
                            final (isPolicyValid, policyError) = passwordValidator.validatePolicy(value);
                            if (!isPolicyValid) {
                              return policyError;
                            }
                            
                            return null;
                          },
                          asyncValidator: (value) async {
                            final passwordValidator = PasswordValidatorService();
                            return await passwordValidator.checkCompromised(value);
                          },
                          onChanged: (value) {
                            // Force rebuild to update password strength indicator
                            setState(() {
                              // Only reset password validation status if the field is empty
                              if (value.isEmpty) {
                                _passwordValidationStatus = ValidationStatus.none;
                              }
                              
                              // If confirm password field is not empty, update its validation status
                              if (_confirmPasswordController.text.isNotEmpty) {
                                // If passwords match, set confirm password validation to valid
                                if (_confirmPasswordController.text == value) {
                                  _confirmPasswordValidationStatus = ValidationStatus.valid;
                                } else {
                                  // If passwords don't match, set confirm password validation to invalid
                                  _confirmPasswordValidationStatus = ValidationStatus.invalid;
                                }
                                
                                // Trigger validation for confirm password field
                                _formKey.currentState?.validate();
                              }
                            });
                          },
                          onValidationComplete: (status) {
                            // Update validation status when validation completes
                            setState(() {
                              _passwordValidationStatus = status;
                              
                              // If valid, move to next field
                              if (_passwordValidationStatus == ValidationStatus.valid) {
                                _confirmPasswordFocusNode.requestFocus();
                              }
                            });
                          },
                        ),
                        // Password strength indicator
                        if (_passwordController.text.isNotEmpty)
                          PasswordStrengthIndicator(
                            password: _passwordController.text,
                          ),
                        const SizedBox(height: 16),
                        
                        // Confirm password field
                        ValidatedTextField(
                          label: 'auth.confirm_password'.tr(),
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocusNode,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(IconMapping.lockOutline),
                          required: true,
                          showValidationStatus: true,
                          preventNextIfInvalid: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'errors.required_field'.tr();
                            }
                            if (value != _passwordController.text) {
                              return 'errors.password_mismatch'.tr();
                            }
                            return null;
                          },
                          // Listen for changes to update validation status in real-time
                          onChanged: (value) {
                            // Update validation status based on whether passwords match
                            setState(() {
                              if (value.isEmpty) {
                                _confirmPasswordValidationStatus = ValidationStatus.none;
                              } else if (value == _passwordController.text) {
                                _confirmPasswordValidationStatus = ValidationStatus.valid;
                              } else {
                                _confirmPasswordValidationStatus = ValidationStatus.invalid;
                              }
                            });
                          },
                          onValidationComplete: (status) {
                            // Only unfocus if valid, don't override the validation status
                            // since we're already handling it in onChanged
                            if (status == ValidationStatus.valid) {
                              _confirmPasswordFocusNode.unfocus();
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // Register button
                        AppButton(
                          label: 'auth.sign_up'.tr(),
                          onPressed: _register,
                          isLoading: _isLoading,
                          isFullWidth: true,
                        ),
                        const SizedBox(height: 16),
                        
                        // Login link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'auth.have_account'.tr(),
                              style: const TextStyle(
                                color: Colors.white, // Changed to white for better visibility
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                context.go('/login', extra: _selectedRole);
                              },
                              child: Text(
                                'auth.sign_in'.tr(),
                                style: const TextStyle(
                                  color: AppTheme.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}