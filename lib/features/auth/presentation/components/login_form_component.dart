import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/validated_text_field.dart';
import '../../../../core/constants/icon_mapping.dart';
import '../../../../services/validation/email_validator_service.dart';

/// A reusable component that displays a login form with email and password fields,
/// a forgot password link, and a login button.
class LoginFormComponent extends StatefulWidget {
  /// Form key for validation.
  final GlobalKey<FormState> formKey;
  
  /// Text controller for the email field.
  final TextEditingController emailController;
  
  /// Text controller for the password field.
  final TextEditingController passwordController;
  
  /// Focus node for the email field.
  final FocusNode emailFocus;
  
  /// Focus node for the password field.
  final FocusNode passwordFocus;
  
  /// Callback function when the login button is pressed.
  final VoidCallback onLogin;
  
  /// Whether the form is in a loading state.
  final bool isLoading;
  
  /// Optional custom text style for the forgot password link.
  final TextStyle? forgotPasswordStyle;
  
  /// Optional custom button style for the login button.
  final ButtonStyle? loginButtonStyle;
  
  /// Optional custom label for the login button.
  final String? loginButtonLabel;
  
  /// Optional custom height for the login button.
  final double? loginButtonHeight;
  
  /// Optional custom border radius for the login button.
  final double? loginButtonBorderRadius;
  
  const LoginFormComponent({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.emailFocus,
    required this.passwordFocus,
    required this.onLogin,
    this.isLoading = false,
    this.forgotPasswordStyle,
    this.loginButtonStyle,
    this.loginButtonLabel,
    this.loginButtonHeight,
    this.loginButtonBorderRadius,
  });

  @override
  State<LoginFormComponent> createState() => _LoginFormComponentState();
}

class _LoginFormComponentState extends State<LoginFormComponent> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
              if (value.length < 6) {
                return 'errors.password_too_short'.tr();
              }
              return null;
            },
            onFieldSubmitted: (_) {
              widget.onLogin();
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
                'auth.forgot_password'.tr(),
                style: widget.forgotPasswordStyle ?? TextStyle(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Login button
          AppButton(
            label: widget.loginButtonLabel ?? 'auth.login'.tr(),
            onPressed: widget.onLogin,
            type: ButtonType.primary,
            isFullWidth: true,
            height: widget.loginButtonHeight ?? 56,
            borderRadius: widget.loginButtonBorderRadius ?? 12,
            isLoading: widget.isLoading,
          ),
        ],
      ),
    );
  }
}