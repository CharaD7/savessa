import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:savessa/services/location_country_service.dart';
import 'package:savessa/core/theme/app_theme.dart';
import 'package:savessa/core/constants/icon_mapping.dart';
import 'package:savessa/shared/widgets/validated_text_field.dart';
import 'package:savessa/features/auth/presentation/components/role_indicator_component.dart';
import 'package:savessa/features/auth/presentation/components/login_signup_toggle_component.dart';
import 'package:savessa/features/auth/presentation/components/login_form_component.dart';
import 'package:savessa/features/auth/presentation/components/signup_form_component.dart';
import 'package:savessa/shared/widgets/app_logo.dart';

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
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Focus nodes for login
  final _loginEmailFocus = FocusNode();
  final _loginPasswordFocus = FocusNode();
  
  // Focus nodes for signup
  final _firstNameFocus = FocusNode();
  final _middleNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _contactFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  
  // Phone field variables
  // ignore: unused_field
  String _countryCode = '+1'; // Default country code (US)
  // ignore: unused_field
  final String _completePhoneNumber = ''; // Complete phone number with country code
  Country _selectedCountry = countries.firstWhere((country) => country.code == 'US'); // Default country
  
  // Track which fields are completed
  bool _firstNameCompleted = false;
  bool _middleNameCompleted = false;
  bool _lastNameCompleted = false;
  bool _contactCompleted = false;
  bool _phoneCompleted = false;
  bool _passwordCompleted = false;
  bool _confirmPasswordCompleted = false;
  
  // Validation status tracking for phone
  final ValidationStatus _phoneValidationStatus = ValidationStatus.none;
  
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

  // Country detect state & preference
  bool _countryDetectionRequested = false;
  bool _isCountryDetecting = false;
  bool _autoDetectEnabled = true;
  
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
    
    // Defer location prompt until phone field focus.
    // Country detection will run on first phone field focus.
    
    // Delay initialization to prevent UI jank during animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load auto-detect preference
      () async {
        final enabled = await LocationCountryService.instance.getAutoDetectEnabled();
        if (mounted) setState(() { _autoDetectEnabled = enabled; });
      }();
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
        _firstNameFocus.addListener(() => _handleFocusChange(_firstNameFocus, 'first_name'));
        _middleNameFocus.addListener(() => _handleFocusChange(_middleNameFocus, 'middle_name'));
        _lastNameFocus.addListener(() => _handleFocusChange(_lastNameFocus, 'last_name'));
        _phoneFocus.addListener(() {
          _handleFocusChange(_phoneFocus, 'phone');
          if (_phoneFocus.hasFocus) {
            _triggerCountryDetectionOnFocus();
          }
        });
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
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameFocus.dispose();
    _middleNameFocus.dispose();
    _lastNameFocus.dispose();
    _contactFocus.dispose();
    _phoneFocus.dispose();
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
      _firstNameCompleted = false;
      _middleNameCompleted = false;
      _lastNameCompleted = false;
      _contactCompleted = false;
      _phoneCompleted = false;
      _passwordCompleted = false;
      _confirmPasswordCompleted = false;
      
      // Clear text fields to prevent validation issues
      if (!_isLoginMode) {
        // Switching to signup mode, clear login fields
        _loginEmailController.clear();
        _loginPasswordController.clear();
      } else {
        // Switching to login mode, clear signup fields
        _firstNameController.clear();
        _middleNameController.clear();
        _lastNameController.clear();
        _contactController.clear();
        _phoneController.clear();
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
          _firstNameFocus.requestFocus();
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
        case 'first_name':
          isCompleted = value.trim().isNotEmpty;
          if (isCompleted != _firstNameCompleted) {
            _firstNameCompleted = isCompleted;
            stateChanged = true;
          }
          break;
        case 'middle_name':
          isCompleted = value.trim().isNotEmpty;
          if (isCompleted != _middleNameCompleted) {
            _middleNameCompleted = isCompleted;
            stateChanged = true;
          }
          break;
        case 'last_name':
          isCompleted = value.trim().isNotEmpty;
          if (isCompleted != _lastNameCompleted) {
            _lastNameCompleted = isCompleted;
            stateChanged = true;
          }
          break;
        case 'phone':
          // Validation for phone - use simple format check for performance
          isCompleted = value.trim().isNotEmpty && value.length >= 8;
          if (isCompleted != _phoneCompleted) {
            _phoneCompleted = isCompleted;
            stateChanged = true;
          }
          break;
        case 'contact':
          // Validation for email - use simple format check for performance
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

  // Trigger detection on first phone focus, respecting preference
  Future<void> _triggerCountryDetectionOnFocus() async {
    if (_countryDetectionRequested) return;
    _countryDetectionRequested = true;
    final enabled = await LocationCountryService.instance.getAutoDetectEnabled();
    if (!enabled) return;
    try {
      setState(() { _isCountryDetecting = true; });
      final country = await LocationCountryService.instance.detectCountry();
      if (!mounted) return;
      setState(() {
        _selectedCountry = country;
        _countryCode = '+${country.dialCode}';
      });
    } catch (e) {
      debugPrint('Error detecting user country: $e');
    } finally {
      if (mounted) setState(() { _isCountryDetecting = false; });
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
      if (_firstNameController.text.isEmpty) {
        _firstNameFocus.requestFocus();
        return;
      } else if (_lastNameController.text.isEmpty) {
        _lastNameFocus.requestFocus();
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
      _firstNameFocus.requestFocus();
    } finally {
      if (mounted && _isLoading) {
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
                  // App logo with glow
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
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                
                  const SizedBox(height: 24),
                  
                  // Login/Signup toggle
                  LoginSignupToggleComponent(
                    mode: _isLoginMode ? 'login' : 'signup',
                    onToggle: _toggleMode,
                    useTabStyle: true,
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
                            if (value && _phoneFocus.hasFocus && !_countryDetectionRequested) {
                              _triggerCountryDetectionOnFocus();
                            }
                          },
                          activeColor: theme.colorScheme.secondary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  // Role indication
                  RoleIndicatorComponent(
                    selectedRole: _selectedRole,
                    prefix: _isLoginMode ? 'Logging in as:' : 'Setting up as:',
                  ),
                  
                  const SizedBox(height: 16),
                  
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
    return LoginFormComponent(
      formKey: _loginFormKey,
      emailController: _loginEmailController,
      passwordController: _loginPasswordController,
      emailFocus: _loginEmailFocus,
      passwordFocus: _loginPasswordFocus,
      onLogin: _login,
      isLoading: _isLoading,
      loginButtonLabel: 'Login',
      loginButtonHeight: 56,
      loginButtonBorderRadius: 12,
    );
  }
  
  // Build signup form
  Widget _buildSignupForm() {
    return SignUpFormComponent(
      formKey: _signupFormKey,
      firstNameController: _firstNameController,
      middleNameController: _middleNameController,
      lastNameController: _lastNameController,
      emailController: _contactController,
      phoneController: _phoneController,
      passwordController: _passwordController,
      confirmPasswordController: _confirmPasswordController,
      firstNameFocus: _firstNameFocus,
      middleNameFocus: _middleNameFocus,
      lastNameFocus: _lastNameFocus,
      emailFocus: _contactFocus,
      phoneFocus: _phoneFocus,
      passwordFocus: _passwordFocus,
      confirmPasswordFocus: _confirmPasswordFocus,
      onSignup: _signup,
      selectedCountry: _selectedCountry,
      showPhoneDetecting: _isCountryDetecting,
      onFieldCompletion: _checkFieldCompletion,
      onCountryChanged: (country) {
        // Persist user's explicit selection so we respect it next time
        LocationCountryService.instance.setUserSelectedIso(country.code);
        setState(() {
          _selectedCountry = country;
          _countryCode = '+${country.dialCode}';
        });
      },
      isLoading: _isLoading,
      emailValidationStatus: _emailValidationStatus,
      phoneValidationStatus: _phoneValidationStatus,
      passwordValidationStatus: _passwordValidationStatus,
      confirmPasswordValidationStatus: _confirmPasswordValidationStatus,
      onEmailValidationComplete: (status) {
        setState(() {
          _emailValidationStatus = status;
          
          // If valid, move to next field
          if (_emailValidationStatus == ValidationStatus.valid) {
            _phoneFocus.requestFocus();
          }
        });
      },
      onPasswordValidationComplete: (status) {
        setState(() {
          _passwordValidationStatus = status;
          
          // If valid, move to next field
          if (_passwordValidationStatus == ValidationStatus.valid) {
            _confirmPasswordFocus.requestFocus();
          }
        });
      },
      onConfirmPasswordValidationComplete: (status) {
        setState(() {
          _confirmPasswordValidationStatus = status;
        });
      },
      firstNameCompleted: _firstNameCompleted,
      middleNameCompleted: _middleNameCompleted,
      lastNameCompleted: _lastNameCompleted,
      phoneCompleted: _phoneCompleted,
      signupButtonLabel: 'Create Account',
      signupButtonHeight: 56,
      signupButtonBorderRadius: 12,
    );
  }
}