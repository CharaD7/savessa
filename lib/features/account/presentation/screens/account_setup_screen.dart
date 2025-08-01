import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:go_router/go_router.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/icon_mapping.dart';
import '../../../../core/utils/text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/validated_text_field.dart';
import '../../../../shared/widgets/password_strength_indicator.dart';
import '../../../../shared/widgets/phone_number_count_indicator.dart';
import '../../../../services/validation/password_validator_service.dart';
import '../../../../services/validation/email_validator_service.dart';
import '../../../../services/validation/phone_validator_service.dart';

class AccountSetupScreen extends StatefulWidget {
  final String? selectedRole;
  
  const AccountSetupScreen({
    super.key,
    this.selectedRole,
  });

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> with SingleTickerProviderStateMixin {
  // Form keys for validation
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  
  // Mode selection (login or signup)
  bool _isLoginMode = false;
  
  // Selected role
  String _selectedRole = 'member'; // Default role
  
  // Text editing controllers for login
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  
  // Text editing controllers for signup
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Phone field variables
  String _countryCode = '+1'; // Default country code (US)
  String _completePhoneNumber = ''; // Complete phone number with country code
  Country _selectedCountry = countries.firstWhere((country) => country.code == 'US'); // Default country
  int _phoneDigitCount = 0; // Current number of digits in phone number
  int _requiredPhoneDigits = 10; // Required number of digits for selected country (default to US)
  bool _isPhoneMaxReached = false; // Whether the maximum digit count has been reached
  
  // Focus nodes for login
  final _loginEmailFocus = FocusNode();
  final _loginPasswordFocus = FocusNode();
  
  // Focus nodes for signup
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _middleNameFocus = FocusNode();
  final _contactFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  
  // Track which fields are completed
  bool _firstNameCompleted = false;
  bool _lastNameCompleted = false;
  bool _middleNameCompleted = false;
  bool _contactCompleted = false;
  bool _phoneCompleted = false;
  bool _passwordCompleted = false;
  bool _confirmPasswordCompleted = false;
  
  // Validation status tracking
  ValidationStatus _phoneValidationStatus = ValidationStatus.none;
  
  // Validation status tracking
  ValidationStatus _emailValidationStatus = ValidationStatus.none;
  ValidationStatus _passwordValidationStatus = ValidationStatus.none;
  ValidationStatus _confirmPasswordValidationStatus = ValidationStatus.none;
  
  // Track if voice guidance is enabled
  bool _voiceGuidanceEnabled = false;
  
  // Animation controller for field completion animations
  late AnimationController _animationController;
  
  // Current field being focused
  String _currentField = '';
  
  // Loading state
  bool _isLoading = false;
  
  // Centralized focus handler to reduce setState calls
  void _handleFocusChange(FocusNode node, String fieldName) {
    if (node.hasFocus && _currentField != fieldName) {
      // Only update state if the field has changed
      setState(() {
        _currentField = fieldName;
      });
      
      if (_voiceGuidanceEnabled) {
        _playFieldGuidance(fieldName);
      }
    }
  }

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
    
    // Set selected role from widget parameter if provided
    if (widget.selectedRole != null) {
      _selectedRole = widget.selectedRole!;
    }
    
    // Detect user's country
    _detectUserCountry();
    
    // Initialize required phone digits based on default country
    _requiredPhoneDigits = PhoneValidatorService.getMaxExpectedLength(_selectedCountry.code);
    
    // Delay initialization to prevent UI jank during animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
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
        
        // Add listeners to all focus nodes using the centralized handler
        _loginEmailFocus.addListener(() => _handleFocusChange(_loginEmailFocus, 'login_email'));
        _loginPasswordFocus.addListener(() => _handleFocusChange(_loginPasswordFocus, 'login_password'));
        _firstNameFocus.addListener(() => _handleFocusChange(_firstNameFocus, 'firstName'));
        _lastNameFocus.addListener(() => _handleFocusChange(_lastNameFocus, 'lastName'));
        _middleNameFocus.addListener(() => _handleFocusChange(_middleNameFocus, 'middleName'));
        _contactFocus.addListener(() => _handleFocusChange(_contactFocus, 'contact'));
        _phoneFocus.addListener(() => _handleFocusChange(_phoneFocus, 'phone'));
        _passwordFocus.addListener(() => _handleFocusChange(_passwordFocus, 'password'));
        _confirmPasswordFocus.addListener(() => _handleFocusChange(_confirmPasswordFocus, 'confirm_password'));
      }
    });
  }
  
  @override
  void dispose() {
    // Dispose login controllers and focus nodes
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _loginEmailFocus.dispose();
    _loginPasswordFocus.dispose();
    
    // Dispose signup controllers and focus nodes
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _middleNameFocus.dispose();
    _contactFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    
    // Dispose animation controller
    _animationController.dispose();
    
    super.dispose();
  }
  
  // Toggle between login and signup modes
  void _toggleMode() {
    // Dismiss keyboard when switching modes
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isLoginMode = !_isLoginMode;
      
      // Reset validation status when switching modes
      _emailValidationStatus = ValidationStatus.none;
      _passwordValidationStatus = ValidationStatus.none;
      _confirmPasswordValidationStatus = ValidationStatus.none;
      _phoneValidationStatus = ValidationStatus.none;
      
      // Reset field completion status
      _firstNameCompleted = false;
      _lastNameCompleted = false;
      _middleNameCompleted = false;
      _contactCompleted = false;
      _phoneCompleted = false;
      _passwordCompleted = false;
      _confirmPasswordCompleted = false;
      
      // Clear text fields to prevent validation issues
      if (!_isLoginMode) {
        // Switching to signup mode, clear login fields
        _loginEmailController.clear();
        _loginPasswordController.clear();
      } else {
        // Switching to login mode, clear signup fields
        _firstNameController.clear();
        _lastNameController.clear();
        _middleNameController.clear();
        _contactController.clear();
        _phoneController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
      }
    });
    
    // Add a small delay before focusing on the first field of the new mode
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        if (_isLoginMode) {
          _loginEmailFocus.requestFocus();
        } else {
          _firstNameFocus.requestFocus();
        }
      }
    });
  }
  
  // Play field guidance audio (to be implemented with actual sound assets)
  void _playFieldGuidance(String field) {
    // TODO: Implement audio playback when assets are available
    debugPrint('Playing guidance for $field field');
  }
  
  // Play field completion sound (to be implemented with actual sound assets)
  void _playFieldCompletionSound() {
    // TODO: Implement sound playback when assets are available
    debugPrint('Playing field completion sound');
  }
  
  // Check if a field is completed and update state
  // Using a debounced approach to reduce frequent state updates
  void _checkFieldCompletion(String field, String value) {
    // Debounce the field completion check to reduce frequent updates
    Future.microtask(() {
      if (!mounted) return;
      
      bool isCompleted = false;
      bool stateChanged = false;
      
      switch (field) {
        case 'firstName':
          isCompleted = value.trim().isNotEmpty;
          if (isCompleted != _firstNameCompleted) {
            _firstNameCompleted = isCompleted;
            stateChanged = true;
          }
          break;
        case 'lastName':
          isCompleted = value.trim().isNotEmpty;
          if (isCompleted != _lastNameCompleted) {
            _lastNameCompleted = isCompleted;
            stateChanged = true;
          }
          break;
        case 'middleName':
          // Middle name is optional, so always mark as completed if it has any value
          isCompleted = true;
          if (isCompleted != _middleNameCompleted) {
            _middleNameCompleted = isCompleted;
            stateChanged = true;
          }
          break;
        case 'contact':
          // Validation for email - use simple format check for performance
          final emailValidator = EmailValidatorService();
          isCompleted = value.trim().isNotEmpty && value.contains('@') && value.contains('.');
          if (isCompleted != _contactCompleted) {
            _contactCompleted = isCompleted;
            stateChanged = true;
          }
          break;
        case 'phone':
          // Phone validation
          isCompleted = value.trim().isNotEmpty;
          if (isCompleted != _phoneCompleted) {
            _phoneCompleted = isCompleted;
            stateChanged = true;
          }
          break;
        case 'password':
          // Use simplified check for performance during typing
          isCompleted = value.length >= 8 && 
                        RegExp(r'[A-Z]').hasMatch(value) && 
                        RegExp(r'[a-z]').hasMatch(value) && 
                        RegExp(r'[0-9]').hasMatch(value);
          if (isCompleted != _passwordCompleted) {
            _passwordCompleted = isCompleted;
            stateChanged = true;
          }
          break;
        case 'confirm_password':
          // Check if passwords match
          isCompleted = value.trim().isNotEmpty && value == _passwordController.text;
          if (isCompleted != _confirmPasswordCompleted) {
            _confirmPasswordCompleted = isCompleted;
            stateChanged = true;
          }
          break;
      }
      
      // Only update state once if any changes were made
      if (stateChanged && mounted) {
        setState(() {
          // State variables were already updated above
        });
        
        // Play sound and animate only if the field was completed
        if (isCompleted) {
          _playFieldCompletionSound();
          _animateFieldCompletion();
        }
      }
    });
  }
  
  // Animate field completion with smoother animation
  void _animateFieldCompletion() {
    // Only animate if the controller is initialized and the widget is mounted
    if (_animationController.isAnimating || !mounted) return;
    
    // Use a try-catch block to handle potential animation errors
    try {
      _animationController.reset();
      // Use a smoother curve for the animation
      _animationController.forward().orCancel.catchError((error) {
        // Silently catch animation cancellation errors
        debugPrint('Animation error: $error');
      });
    } catch (e) {
      // Catch any other errors that might occur during animation
      debugPrint('Animation error: $e');
    }
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
  
  // Login method
  void _login() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    // Validate form
    if (!_loginFormKey.currentState!.validate()) {
      // Find the first field with an error and focus it
      if (_loginEmailController.text.isEmpty) {
        _loginEmailFocus.requestFocus();
        return;
      } else if (_loginPasswordController.text.isEmpty) {
        _loginPasswordFocus.requestFocus();
        return;
      }
      return;
    }

    // Prevent multiple submissions
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, we would use Firebase Auth or similar here
      // For now, we'll just simulate a login
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Login successful!',
            style: TextStyles.successWithGlow(),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Navigate to home screen
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Login error: ${e.toString()}',
            style: TextStyles.errorWithGlow(),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Reset loading state
      setState(() {
        _isLoading = false;
      });
      
      // Focus on email field for retry
      _loginEmailFocus.requestFocus();
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Submit signup form and navigate to dashboard
  void _signup() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    // First check if the form is valid using standard validation
    if (!_signupFormKey.currentState!.validate()) {
      // Find the first field with an error and focus it
      if (_firstNameController.text.isEmpty) {
        _firstNameFocus.requestFocus();
        return;
      } else if (_lastNameController.text.isEmpty) {
        _lastNameFocus.requestFocus();
        return;
      } else if (_contactController.text.isEmpty) {
        _contactFocus.requestFocus();
        return;
      } else if (_phoneController.text.isEmpty) {
        _phoneFocus.requestFocus();
        return;
      } else if (_passwordController.text.isEmpty) {
        _passwordFocus.requestFocus();
        return;
      } else if (_confirmPasswordController.text.isEmpty) {
        _confirmPasswordFocus.requestFocus();
        return;
      }
      return;
    }
    
    // Then check if all fields with async validation are valid
    if (_emailValidationStatus != ValidationStatus.valid) {
      // Trigger email validation if not already valid
      _contactFocus.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please ensure your email is valid before continuing.',
            style: TextStyles.errorWithGlow(),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    
    if (_passwordValidationStatus != ValidationStatus.valid) {
      // Trigger password validation if not already valid
      _passwordFocus.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please ensure your password meets all requirements.',
            style: TextStyles.errorWithGlow(),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    
    if (_confirmPasswordValidationStatus != ValidationStatus.valid) {
      // Trigger confirm password validation if not already valid
      _confirmPasswordFocus.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please ensure your password confirmation matches.',
            style: TextStyles.errorWithGlow(),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Prevent multiple submissions
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, we would use Firebase Auth or similar here
      // For now, we'll just simulate account creation
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account created successfully!',
            style: TextStyles.successWithGlow(),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Navigate to home screen
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Registration error: ${e.toString()}',
            style: TextStyles.errorWithGlow(),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Reset loading state
      setState(() {
        _isLoading = false;
      });
      
      // Focus on the first field for retry
      _firstNameFocus.requestFocus();
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Build password strength indicator widget
  Widget _buildPasswordStrengthIndicator() {
    return PasswordStrengthIndicator(
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Container(
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
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            clipBehavior: Clip.none,
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
                          _isLoginMode ? 'Welcome Back' : 'Account Setup',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLoginMode 
                              ? 'Sign in to continue to Savessa' 
                              : 'Let\'s set up your Savessa account',
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
                  
                  // Login/Signup toggle
                  Container(
                    padding: const EdgeInsets.all(4),
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
                        // Login tab
                        GestureDetector(
                          onTap: () {
                            if (!_isLoginMode) {
                              _toggleMode();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: _isLoginMode 
                                  ? theme.colorScheme.secondary 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              'Login',
                              style: TextStyle(
                                color: _isLoginMode 
                                    ? theme.colorScheme.onSecondary 
                                    : theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        
                        // Signup tab
                        GestureDetector(
                          onTap: () {
                            if (_isLoginMode) {
                              _toggleMode();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isLoginMode 
                                  ? theme.colorScheme.secondary 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: !_isLoginMode 
                                    ? theme.colorScheme.onSecondary 
                                    : theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
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
                  
                  const SizedBox(height: 16),
                  
                  // Role indication
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
                                ? 'Setting up as: Savings Manager'
                                : 'Setting up as: Savings Contributor',
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
                    child: _isLoginMode ? _buildLoginForm() : _buildSignupForm(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Back button
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        context.go('/role');
                      },
                      icon: Icon(
                        FeatherIcons.arrowLeft,
                        color: theme.colorScheme.onPrimary,
                      ),
                      label: Text(
                        'Back to Role Selection',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Build login form
  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          // Email field
          ValidatedTextField(
            label: 'Email',
            controller: _loginEmailController,
            focusNode: _loginEmailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(IconMapping.email),
            required: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_loginPasswordFocus);
            },
          ),
          const SizedBox(height: 16),
          
          // Password field
          ValidatedTextField(
            label: 'Password',
            controller: _loginPasswordController,
            focusNode: _loginPasswordFocus,
            obscureText: true,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(IconMapping.lock),
            required: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              _login();
            },
          ),
          const SizedBox(height: 8),
          
          // Forgot password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                context.go('/forgot-password');
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Login button
          AppButton(
            label: 'Login',
            onPressed: _login,
            type: ButtonType.primary,
            isFullWidth: true,
            height: 56,
            borderRadius: 12,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
  
  // Build signup form
  Widget _buildSignupForm() {
    return Form(
      key: _signupFormKey,
      child: Column(
        children: [
          // First name field
          AppTextField(
            controller: _firstNameController,
            focusNode: _firstNameFocus,
            label: 'First Name',
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(IconMapping.person),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            },
            onChanged: (value) {
              _checkFieldCompletion('firstName', value);
            },
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_lastNameFocus);
            },
            suffixIcon: _firstNameCompleted ? const Icon(IconMapping.checkCircle) : null,
          ),
          const SizedBox(height: 16),
          
          // Last name field
          AppTextField(
            controller: _lastNameController,
            focusNode: _lastNameFocus,
            label: 'Last Name',
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(IconMapping.personOutline),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            },
            onChanged: (value) {
              _checkFieldCompletion('lastName', value);
            },
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_middleNameFocus);
            },
            suffixIcon: _lastNameCompleted ? const Icon(IconMapping.checkCircle) : null,
          ),
          const SizedBox(height: 16),
          
          // Middle name field (optional)
          AppTextField(
            controller: _middleNameController,
            focusNode: _middleNameFocus,
            label: 'Middle Name (Optional)',
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(IconMapping.peopleOutline),
            onChanged: (value) {
              _checkFieldCompletion('middleName', value);
            },
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_contactFocus);
            },
            suffixIcon: _middleNameCompleted ? const Icon(IconMapping.checkCircle) : null,
            // Middle name is optional, so no validator
          ),
          const SizedBox(height: 16),
          
          // Contact/Email field with validation
          ValidatedTextField(
            label: 'Email',
            controller: _contactController,
            focusNode: _contactFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(IconMapping.email),
            required: true,
            showValidationStatus: true,
            preventNextIfInvalid: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              
              final emailValidator = EmailValidatorService();
              if (!emailValidator.isValidFormat(value)) {
                return 'Please enter a valid email';
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
                _checkFieldCompletion('contact', value);
              });
            },
            onValidationComplete: (status) {
              // Update validation status when validation completes
              setState(() {
                _emailValidationStatus = status;
                
                // If valid, move to next field
                if (_emailValidationStatus == ValidationStatus.valid) {
                  _passwordFocus.requestFocus();
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
                      'Phone Number',
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
                focusNode: _phoneFocus,
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
                invalidNumberMessage: 'Invalid phone number',
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
                        content: Text(
                          'Maximum digit count reached ($_requiredPhoneDigits)',
                          style: TextStyles.withGlow(),
                        ),
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
                    
                    // Check field completion
                    _checkFieldCompletion('phone', currentText);
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
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_passwordFocus);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Password field with validation
          ValidatedTextField(
            label: 'Password',
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: true,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(IconMapping.lock),
            required: true,
            showValidationStatus: true,
            preventNextIfInvalid: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
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
                
                _checkFieldCompletion('password', value);
                
                // If confirm password field is not empty, update its validation status
                if (_confirmPasswordController.text.isNotEmpty) {
                  // If passwords match, set confirm password validation to valid
                  if (_confirmPasswordController.text == value) {
                    _confirmPasswordValidationStatus = ValidationStatus.valid;
                    _confirmPasswordCompleted = true;
                  } else {
                    // If passwords don't match, set confirm password validation to invalid
                    _confirmPasswordValidationStatus = ValidationStatus.invalid;
                    _confirmPasswordCompleted = false;
                  }
                  
                  // Trigger validation for confirm password field
                  _signupFormKey.currentState?.validate();
                }
              });
            },
            onValidationComplete: (status) {
              // Update validation status when validation completes
              setState(() {
                _passwordValidationStatus = status;
                
                // If valid, move to next field
                if (_passwordValidationStatus == ValidationStatus.valid) {
                  _confirmPasswordFocus.requestFocus();
                }
              });
            },
          ),
          
          // Password strength indicator
          if (_passwordController.text.isNotEmpty)
            _buildPasswordStrengthIndicator(),
          const SizedBox(height: 16),
          
          // Confirm password field
          ValidatedTextField(
            label: 'Confirm Password',
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocus,
            obscureText: true,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(IconMapping.lockOutline),
            required: true,
            showValidationStatus: true,
            preventNextIfInvalid: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            // Listen for changes to update validation status in real-time
            onChanged: (value) {
              // Update validation status based on whether passwords match
              setState(() {
                if (value.isEmpty) {
                  _confirmPasswordValidationStatus = ValidationStatus.none;
                  _confirmPasswordCompleted = false;
                } else if (value == _passwordController.text) {
                  _confirmPasswordValidationStatus = ValidationStatus.valid;
                  _confirmPasswordCompleted = true;
                } else {
                  _confirmPasswordValidationStatus = ValidationStatus.invalid;
                  _confirmPasswordCompleted = false;
                }
              });
            },
            onFieldSubmitted: (_) {
              if (_confirmPasswordValidationStatus == ValidationStatus.valid) {
                _signup();
              }
            },
          ),
          const SizedBox(height: 24),
          
          // Signup button
          AppButton(
            label: 'Create Account',
            onPressed: _signup,
            type: ButtonType.primary,
            isFullWidth: true,
            height: 56,
            borderRadius: 12,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}