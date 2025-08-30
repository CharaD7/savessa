import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:feather_icons/feather_icons.dart';

import 'package:savessa/core/constants/icon_mapping.dart';
import 'package:savessa/core/theme/app_theme.dart';
import 'package:savessa/shared/widgets/app_logo.dart';
import 'package:savessa/shared/widgets/welcome_header.dart';
import 'package:savessa/features/auth/presentation/components/role_indicator_component.dart';
import 'package:savessa/features/auth/presentation/components/login_signup_toggle_component.dart';
import 'package:savessa/features/auth/presentation/components/login_form_component.dart';
import 'package:savessa/services/database/database_service.dart';
import 'package:provider/provider.dart';
import 'package:savessa/services/user/user_data_service.dart';
import 'package:savessa/services/audit/audit_log_service.dart';
import 'package:savessa/services/auth/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final String? selectedRole;
  final bool hideSignupOption;
  
  const LoginScreen({
    super.key,
    this.selectedRole,
    this.hideSignupOption = false,
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

  bool _emailExists = true;

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
    
    _passwordFocus.addListener(() async {
      if (_passwordFocus.hasFocus) {
        setState(() {
          _currentField = 'password';
        });
        // On moving to password, pre-check if the user exists by email/phone.
        final identifier = _emailController.text.trim();
        if (identifier.isNotEmpty) {
          try {
            final db = DatabaseService();
            final user = await db.getUserByEmailOrPhone(identifier);
            _emailExists = user != null;
            if (!_emailExists && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('No account found with that email or phone.'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          } catch (_) {
            _emailExists = false;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Could not verify account. Check your connection.'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        }
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

    // Capture context-derived objects BEFORE awaits to avoid using context after awaits
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final userSession = Provider.of<UserDataService>(context, listen: false);
    final theme = Theme.of(context);
    final authSvc = Provider.of<AuthService>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      final identifier = _emailController.text.trim();
      final password = _passwordController.text;

      final db = DatabaseService();
      final user = await db.getUserByEmailOrPhone(identifier);
      if (user == null) {
        _emailExists = false;
        messenger.showSnackBar(
          SnackBar(
            content: const Text('No account found with that email or phone.'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        return;
      }

      try {
        final verified = await db.verifyCredentials(identifier: identifier, password: password);
        if (verified == null) {
          messenger.showSnackBar(
            SnackBar(
              content: const Text('Invalid credentials. Please try again.'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
          return;
        }
      } catch (e) {
        final msg = e.toString().contains('INVALID_PASSWORD') ? 'Incorrect password. Please try again.' : 'Authentication failed.';
        messenger.showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        return;
      }

      // Hydrate full user profile from DB and update session
      Map<String, dynamic>? fullUser;
      try {
        final uid = user['id'];
        if (uid != null) {
          fullUser = await db.getUserById(uid.toString());
        }
      } catch (_) {}
      final sessionUser = fullUser ?? user;
      userSession.setUser(sessionUser);
      // Inform AuthService of Postgres session so other parts relying on it (e.g., ProfileForm) work
      try {
        authSvc.setPostgresSessionFromDb(sessionUser);
      } catch (_) {}

      final role = (user['role'] as String?) ?? 'member';
      // Log audit: login_success (fire-and-forget, swallow errors)
      try {
        final uid = (user['id']?.toString()) ?? '';
        await AuditLogService().logAction(
          userId: uid,
          action: 'login_success',
          metadata: {
            'identifier': identifier,
            'role': role,
          },
        );
      } catch (_) {}

      // Navigate using captured router
      if (role == 'admin') {
        router.go('/home/manager');
      } else {
        router.go('/home');
      }
    } catch (e) {
      // Show error message without using context after await
      messenger.showSnackBar(
        SnackBar(
          content: Text('errors.auth_error'.tr()),
          backgroundColor: theme.colorScheme.error,
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
                
                // Reusable welcome header
                WelcomeHeader(
                  title: 'Welcome Back',
                  subtitle: _selectedRole == 'admin'
                      ? 'Logging in as Savings Manager'
                      : 'Logging in as Savings Contributor',
                ),
                
                const SizedBox(height: 24),
                
                // Login/Register toggle - Reusable component (hidden when redirected after signup)
                if (!widget.hideSignupOption)
                  LoginSignupToggleComponent(
                    mode: 'login',
                    selectedRole: _selectedRole,
                    useTabStyle: false,
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
                        activeThumbColor: theme.colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
                  
                const SizedBox(height: 16),
                
                // Role indication - Reusable component
                RoleIndicatorComponent(
                  selectedRole: _selectedRole,
                  prefix: 'Logging in as:',
                ),
                
                const SizedBox(height: 32),
                  
                // Reusable Login Form
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
                  child: LoginFormComponent(
                    formKey: _formKey,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    emailFocus: _emailFocus,
                    passwordFocus: _passwordFocus,
                    onLogin: _login,
                    isLoading: _isLoading,
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