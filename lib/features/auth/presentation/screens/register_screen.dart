import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/validated_text_field.dart';
import '../../../../services/database/database_service.dart';
import '../../../../services/validation/email_validator_service.dart';
import '../../../../services/validation/password_validator_service.dart';
import '../../../../core/constants/icon_mapping.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

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
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    
    super.dispose();
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
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('auth.register'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'S',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Register title
                  Text(
                    'auth.create_account'.tr(),
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
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
                  
                  // Role selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'auth.role'.tr(),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Member option
                            RadioListTile<String>(
                              title: Text('auth.member'.tr()),
                              value: 'member',
                              groupValue: _selectedRole,
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value!;
                                });
                              },
                              activeColor: theme.colorScheme.primary,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            Divider(height: 1, thickness: 1, color: theme.colorScheme.outline.withOpacity(0.1)),
                            // Admin option
                            RadioListTile<String>(
                              title: Text('auth.admin'.tr()),
                              value: 'admin',
                              groupValue: _selectedRole,
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value!;
                                });
                              },
                              activeColor: theme.colorScheme.primary,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ],
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
                        _passwordValidationStatus = ValidationStatus.none;
                        
                        // Also reset confirm password validation if it was previously valid
                        // since changing the password might make the confirmation invalid
                        if (_confirmPasswordValidationStatus == ValidationStatus.valid &&
                            _confirmPasswordController.text.isNotEmpty &&
                            _confirmPasswordController.text != value) {
                          _confirmPasswordValidationStatus = ValidationStatus.invalid;
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
                      // Reset validation status when text changes
                      setState(() {
                        _confirmPasswordValidationStatus = ValidationStatus.none;
                      });
                    },
                    onValidationComplete: (status) {
                      // Update validation status when validation completes
                      setState(() {
                        _confirmPasswordValidationStatus = status;
                        
                        // If valid, unfocus to hide keyboard
                        if (_confirmPasswordValidationStatus == ValidationStatus.valid) {
                          _confirmPasswordFocusNode.unfocus();
                        }
                      });
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
        ),
      ),
    );
  }
}