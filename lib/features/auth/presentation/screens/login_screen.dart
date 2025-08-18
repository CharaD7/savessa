import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:feather_icons/feather_icons.dart';

import 'package:savessa/shared/widgets/app_button.dart';
import 'package:savessa/shared/widgets/validated_text_field.dart';
import 'package:savessa/core/constants/icon_mapping.dart';
import 'package:savessa/core/theme/app_theme.dart';
import 'package:savessa/services/validation/email_validator_service.dart';
import 'package:savessa/services/validation/password_validator_service.dart';
import 'package:savessa/shared/widgets/app_logo.dart';
import 'package:savessa/services/database/database_service.dart';
import 'package:provider/provider.dart';
import 'package:savessa/services/user/user_data_service.dart';

class LoginScreen extends StatefulWidget {
  final String? selectedRole;
  
  const LoginScreen({
    super.key,
    this.selectedRole,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  
  bool _isLoading = false;
  bool _voiceGuidanceEnabled = false;
  String _currentField = '';
  String _selectedRole = 'member'; // Default role
  
  // Animation controller for field completion animations
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
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        setState(() {
          _currentField = 'email';
        });
        if (_voiceGuidanceEnabled) {
          _playFieldGuidance('email');
        }
      }
    });
    
    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus) {
        setState(() {
          _currentField = 'password';
        });
        if (_voiceGuidanceEnabled) {
          _playFieldGuidance('password');
        }
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
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

  void _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final identifier = _emailController.text.trim();
      final password = _passwordController.text;

      final db = DatabaseService();
      final user = await db.getUserByEmailOrPhone(identifier);
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No account found with that email or phone.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      try {
        final verified = await db.verifyCredentials(identifier: identifier, password: password);
        if (verified == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Invalid credentials. Please try again.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          return;
        }
      } catch (e) {
        if (!mounted) return;
        final msg = e.toString().contains('INVALID_PASSWORD') ? 'Incorrect password. Please try again.' : 'Authentication failed.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      if (!mounted) return;
      final userSession = Provider.of<UserDataService>(context, listen: false);
      userSession.setUser(user);

      final role = (user['role'] as String?) ?? 'member';
      if (role == 'admin') {
        context.go('/home/manager');
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('errors.auth_error'.tr()),
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
                const SizedBox(height: 4),
                const AppLogo(size: 100, glow: true, assetPath: 'assets/images/logo.png'),
                const SizedBox(height: 24),
                
                // Header with glassmorphism effect
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
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
                  child: Column(
                    children: [
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedRole == 'admin'
                            ? 'Logging in as Savings Manager'
                            : 'Logging in as Savings Contributor',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Login/Register toggle - Link to register
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
                        'auth.no_account'.tr(),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.go('/register');
                        },
                        child: Text(
                          'auth.sign_up'.tr(),
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
                
                // Role indication
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
                              ? 'Logging in as Savings Manager'
                              : 'Logging in as Savings Contributor',
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
                      children: [
                        // Email field
                        ValidatedTextField(
                          label: 'auth.email'.tr(),
                          controller: _emailController,
                          focusNode: _emailFocus,
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
                            FocusScope.of(context).requestFocus(_passwordFocus);
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Password field
                        ValidatedTextField(
                          label: 'auth.password'.tr(),
                          controller: _passwordController,
                          focusNode: _passwordFocus,
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
                              'auth.forgot_password'.tr(),
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Login button
                        AppButton(
                          label: 'auth.login'.tr(),
                          onPressed: _login,
                          type: ButtonType.primary,
                          isFullWidth: true,
                          height: 56,
                          borderRadius: 12,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Back button to role selection
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
    );
  }
}