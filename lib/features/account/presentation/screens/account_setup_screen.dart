import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/icon_mapping.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/validated_text_field.dart';
import '../../../../shared/widgets/password_strength_indicator.dart';
import '../../../../shared/widgets/auth/login_form.dart';
import '../../../../shared/widgets/auth/signup_form.dart';
import '../../../../shared/widgets/auth/role_type_indicator.dart';
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
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Focus nodes for login
  final _loginEmailFocus = FocusNode();
  final _loginPasswordFocus = FocusNode();
  
  // Focus nodes for signup
  final _nameFocus = FocusNode();
  final _contactFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  
  // Track which fields are completed
  bool _nameCompleted = false;
  bool _contactCompleted = false;
  bool _passwordCompleted = false;
  bool _confirmPasswordCompleted = false;
  
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

  @override
  void initState() {
    super.initState();
    
    // Set selected role from widget parameter if provided
    if (widget.selectedRole != null) {
      _selectedRole = widget.selectedRole!;
    }
    
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
        _nameFocus.addListener(() => _handleFocusChange(_nameFocus, 'name'));
        _contactFocus.addListener(() => _handleFocusChange(_contactFocus, 'contact'));
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
    _nameController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _contactFocus.dispose();
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
      
      // Reset field completion status
      _nameCompleted = false;
      _contactCompleted = false;
      _passwordCompleted = false;
      _confirmPasswordCompleted = false;
      
      // Clear text fields to prevent validation issues
      if (!_isLoginMode) {
        // Switching to signup mode, clear login fields
        _loginEmailController.clear();
        _loginPasswordController.clear();
      } else {
        // Switching to login mode, clear signup fields
        _nameController.clear();
        _contactController.clear();
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
          _nameFocus.requestFocus();
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
        case 'name':
          isCompleted = value.trim().isNotEmpty;
          if (isCompleted != _nameCompleted) {
            _nameCompleted = isCompleted;
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
        const SnackBar(
          content: Text('Login successful!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navigate to home screen
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login error: ${e.toString()}'),
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
      if (_nameController.text.isEmpty) {
        _nameFocus.requestFocus();
        return;
      } else if (_contactController.text.isEmpty) {
        _contactFocus.requestFocus();
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
          content: const Text('Please ensure your email is valid before continuing.'),
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
          content: const Text('Please ensure your password meets all requirements.'),
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
          content: const Text('Please ensure your password confirmation matches.'),
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
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navigate to home screen
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Reset loading state
      setState(() {
        _isLoading = false;
      });
      
      // Focus on the first field for retry
      _nameFocus.requestFocus();
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
                  RoleTypeIndicator(
                    role: _selectedRole,
                    prefix: 'Setting up as:',
                    colorScheme: theme.colorScheme,
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
    return LoginForm(
      formKey: _loginFormKey,
      emailController: _loginEmailController,
      passwordController: _loginPasswordController,
      emailFocus: _loginEmailFocus,
      passwordFocus: _loginPasswordFocus,
      isLoading: _isLoading,
      onLogin: _login,
      colorScheme: Theme.of(context).colorScheme,
    );
  }
  
  // Build signup form
  Widget _buildSignupForm() {
    return SignUpForm(
      formKey: _signupFormKey,
      nameController: _nameController,
      emailController: _contactController,
      passwordController: _passwordController,
      confirmPasswordController: _confirmPasswordController,
      nameFocus: _nameFocus,
      emailFocus: _contactFocus,
      passwordFocus: _passwordFocus,
      confirmPasswordFocus: _confirmPasswordFocus,
      isLoading: _isLoading,
      onSignup: _signup,
      onFieldCompleted: _checkFieldCompletion,
      colorScheme: Theme.of(context).colorScheme,
      signupButtonLabel: 'Create Account',
    );
  }
}