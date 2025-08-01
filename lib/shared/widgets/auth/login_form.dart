import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/validated_text_field.dart';
import '../../../../core/constants/icon_mapping.dart';
import '../../../../services/validation/email_validator_service.dart';
import '../../../../services/validation/password_validator_service.dart';

/// A reusable login form component that can be used across different screens.
class LoginForm extends StatefulWidget {
  /// The form key for validation
  final GlobalKey<FormState> formKey;
  
  /// The email controller
  final TextEditingController emailController;
  
  /// The password controller
  final TextEditingController passwordController;
  
  /// The email focus node
  final FocusNode emailFocus;
  
  /// The password focus node
  final FocusNode passwordFocus;
  
  /// Whether the form is in a loading state
  final bool isLoading;
  
  /// Callback for when the login button is pressed
  final VoidCallback onLogin;
  
  /// Whether to show the forgot password link
  final bool showForgotPassword;
  
  /// The route to navigate to when the forgot password link is pressed
  final String forgotPasswordRoute;
  
  /// The color scheme to use for the form
  final ColorScheme? colorScheme;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.emailFocus,
    required this.passwordFocus,
    required this.isLoading,
    required this.onLogin,
    this.showForgotPassword = true,
    this.forgotPasswordRoute = '/forgot-password',
    this.colorScheme,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = widget.colorScheme ?? theme.colorScheme;
    
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          // Email field
          ValidatedTextField(
            label: 'auth.email'.tr(),
            controller: widget.emailController,
            focusNode: widget.emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(IconMapping.email),
            required: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'errors.required_field'.tr();
              }
              
              // Use EmailValidatorService for better validation
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
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(widget.passwordFocus);
            },
          ),
          const SizedBox(height: 16),
          
          // Password field
          ValidatedTextField(
            label: 'auth.password'.tr(),
            controller: widget.passwordController,
            focusNode: widget.passwordFocus,
            obscureText: true,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(IconMapping.lock),
            required: true,
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
            onFieldSubmitted: (_) {
              widget.onLogin();
            },
          ),
          
          // Forgot password link
          if (widget.showForgotPassword) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  context.go(widget.forgotPasswordRoute);
                },
                child: Text(
                  'auth.forgot_password'.tr(),
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Login button
          AppButton(
            label: 'auth.login'.tr(),
            onPressed: widget.onLogin,
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