import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/validated_text_field.dart';
import '../../../../shared/widgets/password_strength_indicator.dart';
import '../../../../core/constants/icon_mapping.dart';
import '../../../../services/validation/email_validator_service.dart';
import '../../../../services/validation/password_validator_service.dart';

// Using ValidationStatus from validated_text_field.dart

/// A reusable signup form component that can be used across different screens.
class SignUpForm extends StatefulWidget {
  /// The form key for validation
  final GlobalKey<FormState> formKey;
  
  /// The name controller
  final TextEditingController nameController;
  
  /// The email controller
  final TextEditingController emailController;
  
  /// The password controller
  final TextEditingController passwordController;
  
  /// The confirm password controller
  final TextEditingController confirmPasswordController;
  
  /// The name focus node
  final FocusNode nameFocus;
  
  /// The email focus node
  final FocusNode emailFocus;
  
  /// The password focus node
  final FocusNode passwordFocus;
  
  /// The confirm password focus node
  final FocusNode confirmPasswordFocus;
  
  /// Whether the form is in a loading state
  final bool isLoading;
  
  /// Callback for when the signup button is pressed
  final VoidCallback onSignup;
  
  /// Callback for when a field is completed
  final Function(String field, String value)? onFieldCompleted;
  
  /// The color scheme to use for the form
  final ColorScheme? colorScheme;
  
  /// Whether to use the simplified version of the form
  final bool simplified;
  
  /// The label for the signup button
  final String signupButtonLabel;

  const SignUpForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.nameFocus,
    required this.emailFocus,
    required this.passwordFocus,
    required this.confirmPasswordFocus,
    required this.isLoading,
    required this.onSignup,
    this.onFieldCompleted,
    this.colorScheme,
    this.simplified = false,
    this.signupButtonLabel = 'auth.create_account',
  });

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  // Validation status tracking
  ValidationStatus _emailValidationStatus = ValidationStatus.none;
  ValidationStatus _passwordValidationStatus = ValidationStatus.none;
  ValidationStatus _confirmPasswordValidationStatus = ValidationStatus.none;
  
  // Track which fields are completed
  bool _nameCompleted = false;
  bool _emailCompleted = false;
  bool _passwordCompleted = false;
  bool _confirmPasswordCompleted = false;
  
  @override
  void initState() {
    super.initState();
    
    // Check initial field completion status
    _checkFieldCompletion('name', widget.nameController.text);
    _checkFieldCompletion('email', widget.emailController.text);
    _checkFieldCompletion('password', widget.passwordController.text);
    _checkFieldCompletion('confirmPassword', widget.confirmPasswordController.text);
  }
  
  /// Check if a field is completed and update the corresponding state variable
  void _checkFieldCompletion(String field, String value) {
    bool isCompleted = value.trim().isNotEmpty;
    
    if (field == 'name') {
      if (_nameCompleted != isCompleted) {
        setState(() {
          _nameCompleted = isCompleted;
        });
      }
    } else if (field == 'email') {
      if (_emailCompleted != isCompleted) {
        setState(() {
          _emailCompleted = isCompleted;
        });
      }
    } else if (field == 'password') {
      if (_passwordCompleted != isCompleted) {
        setState(() {
          _passwordCompleted = isCompleted;
        });
      }
    } else if (field == 'confirmPassword') {
      bool passwordsMatch = value == widget.passwordController.text && value.isNotEmpty;
      if (_confirmPasswordCompleted != passwordsMatch) {
        setState(() {
          _confirmPasswordCompleted = passwordsMatch;
        });
      }
    }
    
    // Call the onFieldCompleted callback if provided
    if (widget.onFieldCompleted != null) {
      widget.onFieldCompleted!(field, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = widget.colorScheme ?? theme.colorScheme;
    
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          // Name field
          AppTextField(
            controller: widget.nameController,
            focusNode: widget.nameFocus,
            label: 'auth.full_name'.tr(),
            hint: 'auth.enter_full_name'.tr(),
            prefixIcon: const Icon(IconMapping.person),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'errors.required_field'.tr();
              }
              return null;
            },
            onChanged: (value) {
              _checkFieldCompletion('name', value);
            },
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(widget.emailFocus);
            },
            suffixIcon: _nameCompleted ? const Icon(IconMapping.checkCircle) : null,
          ),
          const SizedBox(height: 16),
          
          // Email field with validation
          ValidatedTextField(
            label: 'auth.email'.tr(),
            controller: widget.emailController,
            focusNode: widget.emailFocus,
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
                return (false, 'errors.email_already_registered'.tr());
              }
              
              // Then validate email existence and activity
              return await emailValidator.validateEmail(value);
            },
            onChanged: (value) {
              // Reset validation status when text changes
              setState(() {
                _emailValidationStatus = ValidationStatus.none;
                _checkFieldCompletion('email', value);
              });
            },
            onValidationComplete: (status) {
              // Update validation status when validation completes
              setState(() {
                _emailValidationStatus = status;
                
                // If valid, move to next field
                if (_emailValidationStatus == ValidationStatus.valid) {
                  widget.passwordFocus.requestFocus();
                }
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Password field with validation
          ValidatedTextField(
            label: 'auth.password'.tr(),
            controller: widget.passwordController,
            focusNode: widget.passwordFocus,
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
                
                _checkFieldCompletion('password', value);
                
                // If confirm password field is not empty, update its validation status
                if (widget.confirmPasswordController.text.isNotEmpty) {
                  // If passwords match, set confirm password validation to valid
                  if (widget.confirmPasswordController.text == value) {
                    _confirmPasswordValidationStatus = ValidationStatus.valid;
                    _confirmPasswordCompleted = true;
                  } else {
                    // If passwords don't match, set confirm password validation to invalid
                    _confirmPasswordValidationStatus = ValidationStatus.invalid;
                    _confirmPasswordCompleted = false;
                  }
                  
                  // Trigger validation for confirm password field
                  widget.formKey.currentState?.validate();
                }
              });
            },
            onValidationComplete: (status) {
              // Update validation status when validation completes
              setState(() {
                _passwordValidationStatus = status;
                
                // If valid, move to next field
                if (_passwordValidationStatus == ValidationStatus.valid) {
                  widget.confirmPasswordFocus.requestFocus();
                }
              });
            },
          ),
          
          // Password strength indicator
          if (widget.passwordController.text.isNotEmpty)
            PasswordStrengthIndicator(
              password: widget.passwordController.text,
            ),
          const SizedBox(height: 16),
          
          // Confirm password field
          ValidatedTextField(
            label: 'auth.confirm_password'.tr(),
            controller: widget.confirmPasswordController,
            focusNode: widget.confirmPasswordFocus,
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
              if (value != widget.passwordController.text) {
                return 'errors.passwords_do_not_match'.tr();
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
                } else if (value == widget.passwordController.text) {
                  _confirmPasswordValidationStatus = ValidationStatus.valid;
                  _confirmPasswordCompleted = true;
                } else {
                  _confirmPasswordValidationStatus = ValidationStatus.invalid;
                  _confirmPasswordCompleted = false;
                }
                
                _checkFieldCompletion('confirmPassword', value);
              });
            },
            onFieldSubmitted: (_) {
              if (_confirmPasswordValidationStatus == ValidationStatus.valid) {
                widget.onSignup();
              }
            },
          ),
          const SizedBox(height: 24),
          
          // Signup button
          AppButton(
            label: widget.signupButtonLabel.tr(),
            onPressed: widget.onSignup,
            type: ButtonType.primary,
            isFullWidth: true,
            height: 56,
            borderRadius: 12,
            isLoading: widget.isLoading,
          ),
        ],
      ),
    );
  }
}