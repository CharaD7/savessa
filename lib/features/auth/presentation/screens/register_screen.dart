import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/validated_text_field.dart';
import '../../../../services/database/database_service.dart';
import '../../../../services/validation/email_validator_service.dart';
import '../../../../services/validation/password_validator_service.dart';
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
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _selectedRole = 'member'; // Default role
  
  // Validation status tracking
  ValidationStatus _emailValidationStatus = ValidationStatus.none;
  ValidationStatus _passwordValidationStatus = ValidationStatus.none;
  ValidationStatus _confirmPasswordValidationStatus = ValidationStatus.none;
  
  // Focus nodes to control field focus
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _otherNamesFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  
  // Voice guidance and animation
  bool _voiceGuidanceEnabled = false;
  String _currentField = '';
  late AnimationController _animationController;
  
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
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    
    // Dispose focus nodes
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _otherNamesFocusNode.dispose();
    _emailFocusNode.dispose();
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

    setState(() {
      _isLoading = true;
    });

    try {
      // Collect user data
      final userData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'other_names': _otherNamesController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole,
        'password': _passwordController.text, // In a real app, this would be hashed
      };
      
      // Use the DatabaseService to create a new user
      final dbService = DatabaseService();
      
      // Check if user with this email already exists
      // This is a double-check since we already validated the email
      final existingUser = await dbService.getUserByEmail(userData['email']!);
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
      
      // Navigate to login screen
      context.go('/login');
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
                            ? 'Register as a Savings Manager' 
                            : 'Register as a Savings Contributor',
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
                          context.go('/login');
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
                                _passwordFocusNode.requestFocus();
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Phone field
                        AppTextField(
                          label: 'auth.phone'.tr(),
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(IconMapping.phone),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'errors.required_field'.tr();
                            }
                            // Simple phone validation
                            if (value.length < 10) {
                              return 'errors.invalid_phone'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Role selection (disabled, showing selected role)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'auth.role'.tr(),
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Member option
                                  RadioListTile<String>(
                                    title: Text(
                                      'auth.member'.tr(),
                                      style: TextStyle(
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                    value: 'member',
                                    groupValue: _selectedRole,
                                    onChanged: null, // Disabled
                                    activeColor: theme.colorScheme.secondary,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  Divider(height: 1, thickness: 1, color: Colors.white.withOpacity(0.1)),
                                  // Admin option
                                  RadioListTile<String>(
                                    title: Text(
                                      'auth.admin'.tr(),
                                      style: TextStyle(
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                    value: 'admin',
                                    groupValue: _selectedRole,
                                    onChanged: null, // Disabled
                                    activeColor: theme.colorScheme.secondary,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Role selection explanation
                            Text(
                              _selectedRole == 'admin'
                                  ? 'You selected "I manage savings" role'
                                  : 'You selected "I contribute savings" role',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary.withOpacity(0.7),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                        
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
                            Text('auth.have_account'.tr()),
                            TextButton(
                              onPressed: () {
                                context.go('/login');
                              },
                              child: Text('auth.sign_in'.tr()),
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