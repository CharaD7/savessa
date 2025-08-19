import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:savessa/services/location_country_service.dart';
import 'package:savessa/shared/widgets/world_flag_overlay.dart';

import 'package:savessa/shared/widgets/app_button.dart';
import 'package:savessa/shared/widgets/app_text_field.dart';
import 'package:savessa/shared/widgets/validated_text_field.dart';
import 'package:savessa/shared/widgets/password_strength_indicator.dart';
import 'package:savessa/services/database/database_service.dart';
import 'package:savessa/services/validation/email_validator_service.dart';
import 'package:savessa/services/validation/password_validator_service.dart';
import 'package:savessa/services/validation/phone_validator_service.dart';
import 'package:savessa/core/constants/icon_mapping.dart';
import 'package:savessa/core/theme/app_theme.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:savessa/shared/widgets/app_logo.dart';
import 'package:savessa/shared/widgets/welcome_header.dart';
import 'package:savessa/core/roles/role.dart';

class RegisterScreen extends StatefulWidget {
  // Optional override for detection in tests
  final Future<Country> Function()? detectCountryFn;
  final String? selectedRole;
  
  const RegisterScreen({
    super.key, 
    this.selectedRole,
    this.detectCountryFn,
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
  
  // Validation status tracking
  ValidationStatus _emailValidationStatus = ValidationStatus.none;
  ValidationStatus _confirmEmailValidationStatus = ValidationStatus.none;
  ValidationStatus _passwordValidationStatus = ValidationStatus.none;
  ValidationStatus _confirmPasswordValidationStatus = ValidationStatus.none;
  // ignore: unused_field
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
  
  bool _countryDetectionRequested = false;
  bool _isCountryDetecting = false;
  bool _autoDetectEnabled = true;

  void _triggerCountryDetectionOnFocus() async {
    if (_countryDetectionRequested) return;
    _countryDetectionRequested = true;
    // Respect the auto-detect preference
    final enabled = await LocationCountryService.instance.getAutoDetectEnabled();
    if (!enabled) return;
    _detectUserCountry();
  }

  // Use a shared service to detect the current country without hardcoding
  Future<void> _detectUserCountry() async {
    try {
      setState(() { _isCountryDetecting = true; });
      final country = await (widget.detectCountryFn != null
          ? widget.detectCountryFn!()
          : LocationCountryService.instance.detectCountry());
      if (!mounted) return;
      setState(() {
        _selectedCountry = country;
        _countryCode = '+${country.dialCode}';
      });
      debugPrint('Detected country: ${country.name} (${country.code})');
    } catch (e) {
      debugPrint('Error detecting user country: $e');
    } finally {
      if (mounted) setState(() { _isCountryDetecting = false; });
    }
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
    
    // Do not prompt for location until the user focuses the phone field
    // Country detection will run on first phone field focus.
    
    // Load auto-detect preference
    () async {
      final enabled = await LocationCountryService.instance.getAutoDetectEnabled();
      if (mounted) setState(() { _autoDetectEnabled = enabled; });
    }();

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
        // Trigger country detection on first focus
        _triggerCountryDetectionOnFocus();
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
'role': RoleX.normalizeLabel(_selectedRole),
        'password': _passwordController.text, // In a real app, this would be hashed
        'email_verified': true, // Mark as verified since we've verified it
      };
      
      // Use the DatabaseService to create a new user
      final dbService = DatabaseService();
      await dbService.connect();
      
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
      
      // Navigate to login screen with selected role and hide sign-up option on arrival
      context.go('/login', extra: {'role': _selectedRole, 'hideSignup': true});
    } catch (e) {
      if (!mounted) return;
      
      // Map database exceptions to friendly messages
      final err = e.toString();
      String msg = 'Registration failed. Please try again.';
      if (err.contains('EMAIL_EXISTS')) {
        msg = 'Email already registered. Please use a different email.';
      } else if (err.contains('PHONE_EXISTS')) {
        msg = 'Phone number already registered. Please use a different phone number.';
      }
      
      // Show error message and do NOT authenticate
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
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
                // App logo with glow
                const AppLogo(size: 100, glow: true, assetPath: 'assets/images/logo.png'),
                const SizedBox(height: 24),
                
                // Reusable welcome header
                WelcomeHeader(
                  title: 'Create Account',
                  subtitle: widget.selectedRole == 'admin'
                      ? 'Setting up as Savings Manager'
                      : 'Setting up as Savings Contributor',
                ),
                
                const SizedBox(height: 24),
                
                // Login/Register toggle - Link to login
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
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
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
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
                
                // Auto-detect Country toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
FeatherIcons.mapPin,
                        color: theme.colorScheme.onPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Auto-detect Country',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _autoDetectEnabled,
                        onChanged: (value) async {
                          setState(() { _autoDetectEnabled = value; });
                          await LocationCountryService.instance.setAutoDetectEnabled(value);
                          if (value && _phoneFocusNode.hasFocus && !_countryDetectionRequested) {
                            _triggerCountryDetectionOnFocus();
                          }
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
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
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
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 8),
                              child: Text(
                                'auth.phone'.tr(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                IntlPhoneField(
                                  controller: _phoneController,
                                  focusNode: _phoneFocusNode,
                                  decoration: InputDecoration(
                                hintText: 'Enter phone number',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
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
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red, width: 2),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red, width: 2),
                                ),
                                suffixIcon: _isCountryDetecting
                                    ? Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                                          ),
                                        ),
                                      )
                                    : null,
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
                                IconMapping.arrowDownward,
                                color: Colors.white,
                                size: 18,
                              ),
                              flagsButtonPadding: const EdgeInsets.symmetric(horizontal: 8),
                              showDropdownIcon: true,
                              disableLengthCheck: false,
                              invalidNumberMessage: 'errors.invalid_phone'.tr(),
                              onChanged: (phone) {
                                setState(() {
                                  _countryCode = phone.countryCode;
                                  _completePhoneNumber = phone.completeNumber;
                                  // We don't update _selectedCountry here as it's handled in onCountryChanged
                                  _phoneValidationStatus = ValidationStatus.valid;
                                });
                              },
                              onCountryChanged: (country) {
                                setState(() {
                                  _countryCode = '+${country.dialCode}';
                                  _selectedCountry = country;
                                  // Update complete phone number
                                  if (_phoneController.text.isNotEmpty) {
                                    _completePhoneNumber = '$_countryCode${_phoneController.text}';
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
                                if (_isCountryDetecting)
                                  const WorldFlagOverlay(visible: true),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Role indication (simplified)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
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