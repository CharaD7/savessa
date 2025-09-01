import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:feather_icons/feather_icons.dart';
import 'dart:async';

import 'package:savessa/core/constants/icon_mapping.dart';
import 'package:savessa/core/theme/app_theme.dart';
import 'package:savessa/core/models/password_reset_token.dart';
import 'package:savessa/services/auth/password_reset_service.dart';
import 'package:savessa/shared/widgets/app_logo.dart';
import 'package:savessa/shared/widgets/welcome_header.dart';
import 'package:savessa/shared/widgets/validated_text_field.dart';
import 'package:savessa/shared/widgets/app_button.dart';
import 'package:savessa/shared/widgets/password_strength_widget.dart';
import 'package:savessa/services/validation/email_validator_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _identifierController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Form keys
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();
  
  // Focus nodes
  final _identifierFocus = FocusNode();
  final _tokenFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  
  // State variables
  int _currentStep = 0;
  PasswordResetType _selectedMethod = PasswordResetType.email;
  bool _isLoading = false;
  bool _voiceGuidanceEnabled = false;
  
  // Resend timer
  Timer? _resendTimer;
  int _resendCountdown = 0;
  
  // Services
  final _passwordResetService = PasswordResetService();
  
  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Set system UI
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _identifierFocus.dispose();
    _tokenFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _resendTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleVoiceGuidance() {
    setState(() {
      _voiceGuidanceEnabled = !_voiceGuidanceEnabled;
    });
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  Future<void> _sendResetCode() async {
    if (!_step1FormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await _passwordResetService.initiatePasswordReset(
        identifier: _identifierController.text.trim(),
        type: _selectedMethod,
      );

      if (!mounted) return;

      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        _nextStep();
        _startResendTimer();
      } else {
        Color snackBarColor = Colors.red;
        if (result.type == PasswordResetResultType.rateLimited) {
          snackBarColor = Colors.orange;
        }
        
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: snackBarColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyToken() async {
    if (!_step2FormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      final token = await _passwordResetService.validateResetToken(
        _tokenController.text.trim(),
      );

      if (!mounted) return;

      if (token != null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Reset code verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _nextStep();
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Invalid or expired reset code. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Verification failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!_step3FormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      final result = await _passwordResetService.resetPassword(
        token: _tokenController.text.trim(),
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Navigate to success screen
        router.go('/reset-password-success');
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Password reset failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;

    await _sendResetCode();
  }

  void _startResendTimer() {
    _resendCountdown = 60; // 60 seconds countdown
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
        
        if (_resendCountdown <= 0) {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App logo
                    const SizedBox(height: 4),
                    const AppLogo(size: 80, glow: true, assetPath: 'assets/images/logo.png'),
                    const SizedBox(height: 24),
                    
                    // Welcome header with step info
                    WelcomeHeader(
                      title: 'auth.forgot_password_title'.tr(),
                      subtitle: _getStepSubtitle(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Voice guidance toggle
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
                            onChanged: (value) => _toggleVoiceGuidance(),
                            activeThumbColor: theme.colorScheme.secondary,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Step indicator
                    _buildStepIndicator(),
                    
                    const SizedBox(height: 32),
                    
                    // Main content card
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
                      child: _buildCurrentStep(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Back button
                    if (_currentStep == 0) ...[
                      Center(
                        child: TextButton.icon(
                          onPressed: () => context.go('/login'),
                          icon: Icon(
                            FeatherIcons.arrowLeft,
                            color: theme.colorScheme.onPrimary,
                          ),
                          label: Text(
                            'Back to Login',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Center(
                        child: TextButton.icon(
                          onPressed: _previousStep,
                          icon: Icon(
                            FeatherIcons.arrowLeft,
                            color: theme.colorScheme.onPrimary,
                          ),
                          label: Text(
                            'common.back'.tr(),
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'auth.forgot_password_subtitle'.tr();
      case 1:
        return '${'auth.reset_code_instructions'.tr()} ${_selectedMethod.value}';
      case 2:
        return 'auth.create_new_password'.tr();
      default:
        return '';
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index <= _currentStep;
        final isCurrent = index == _currentStep;
        
        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.gold : Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (index < 2) ...[
              Container(
                width: 40,
                height: 2,
                color: index < _currentStep 
                    ? AppTheme.gold 
                    : Colors.white.withValues(alpha: 0.3),
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return _buildStep1();
    }
  }

  Widget _buildStep1() {
    return Form(
      key: _step1FormKey,
      child: Column(
        children: [
          // Method selection
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMethod = PasswordResetType.email),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedMethod == PasswordResetType.email
                          ? AppTheme.gold
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedMethod == PasswordResetType.email
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          IconMapping.email,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'auth.reset_method_email'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMethod = PasswordResetType.sms),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedMethod == PasswordResetType.sms
                          ? AppTheme.gold
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedMethod == PasswordResetType.sms
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          IconMapping.phone,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'auth.reset_method_sms'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Input field
          ValidatedTextField(
            label: _selectedMethod == PasswordResetType.email 
                ? 'auth.email'.tr() 
                : 'auth.phone'.tr(),
            controller: _identifierController,
            focusNode: _identifierFocus,
            keyboardType: _selectedMethod == PasswordResetType.email 
                ? TextInputType.emailAddress 
                : TextInputType.phone,
            textInputAction: TextInputAction.done,
            prefixIcon: Icon(_selectedMethod == PasswordResetType.email 
                ? IconMapping.email 
                : IconMapping.phone),
            required: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'errors.required_field'.tr();
              }
              
              if (_selectedMethod == PasswordResetType.email) {
                final emailValidator = EmailValidatorService();
                if (!emailValidator.isValidFormat(value)) {
                  return 'errors.invalid_email'.tr();
                }
              } else {
                // Basic phone validation
                final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
                final cleanPhone = value.replaceAll(RegExp(r'[\s-()]'), '');
                if (!phoneRegex.hasMatch(cleanPhone)) {
                  return 'errors.invalid_phone'.tr();
                }
              }
              
              return null;
            },
            onFieldSubmitted: (_) => _sendResetCode(),
          ),
          const SizedBox(height: 24),
          
          // Send button
          AppButton(
            label: 'auth.send_reset_code'.tr(),
            onPressed: _sendResetCode,
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

  Widget _buildStep2() {
    return Form(
      key: _step2FormKey,
      child: Column(
        children: [
          ValidatedTextField(
            label: 'auth.enter_reset_code'.tr(),
            controller: _tokenController,
            focusNode: _tokenFocus,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(IconMapping.lock),
            required: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'errors.required_field'.tr();
              }
              return null;
            },
            onFieldSubmitted: (_) => _verifyToken(),
          ),
          const SizedBox(height: 16),
          
          // Resend option
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Didn't receive the code?",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              TextButton(
                onPressed: _resendCountdown > 0 ? null : _resendCode,
                child: Text(
                  _resendCountdown > 0 
                      ? '${'auth.resend_in'.tr()} ${_resendCountdown}s'
                      : 'auth.resend_code'.tr(),
                  style: TextStyle(
                    color: _resendCountdown > 0 
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppTheme.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Verify button
          AppButton(
            label: 'auth.verify_code'.tr(),
            onPressed: _verifyToken,
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

  Widget _buildStep3() {
    return Form(
      key: _step3FormKey,
      child: Column(
        children: [
          ValidatedTextField(
            label: 'auth.new_password'.tr(),
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: true,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(IconMapping.lock),
            required: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'errors.required_field'.tr();
              }
              if (value.length < 8) {
                return 'errors.password_too_short'.tr();
              }
              return null;
            },
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_confirmPasswordFocus);
            },
            onChanged: (value) => setState(() {}), // Trigger rebuild for password strength
          ),
          const SizedBox(height: 16),
          
          ValidatedTextField(
            label: 'auth.confirm_new_password'.tr(),
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocus,
            obscureText: true,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(IconMapping.lock),
            required: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'errors.required_field'.tr();
              }
              if (value != _passwordController.text) {
                return 'errors.password_mismatch'.tr();
              }
              return null;
            },
            onFieldSubmitted: (_) => _resetPassword(),
          ),
          const SizedBox(height: 16),
          
          // Password strength indicator
          if (_passwordController.text.isNotEmpty)
            PasswordStrengthWidget(password: _passwordController.text),
          
          const SizedBox(height: 24),
          
          // Reset password button
          AppButton(
            label: 'auth.reset_password_complete'.tr(),
            onPressed: _resetPassword,
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
