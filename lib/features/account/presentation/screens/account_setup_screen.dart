import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/icon_mapping.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/validated_text_field.dart';
import '../../../../services/validation/password_validator_service.dart';
import '../../../../services/validation/email_validator_service.dart';

class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> with SingleTickerProviderStateMixin {
  // Form keys for validation
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  
  // Mode selection (login or signup)
  bool _isLoginMode = false;
  
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
    
    // Add listeners to login focus nodes
    _loginEmailFocus.addListener(() {
      if (_loginEmailFocus.hasFocus) {
        setState(() {
          _currentField = 'login_email';
        });
        if (_voiceGuidanceEnabled) {
          _playFieldGuidance('email');
        }
      }
    });
    
    _loginPasswordFocus.addListener(() {
      if (_loginPasswordFocus.hasFocus) {
        setState(() {
          _currentField = 'login_password';
        });
        if (_voiceGuidanceEnabled) {
          _playFieldGuidance('password');
        }
      }
    });
    
    // Add listeners to signup focus nodes
    _nameFocus.addListener(() {
      if (_nameFocus.hasFocus) {
        setState(() {
          _currentField = 'name';
        });
        if (_voiceGuidanceEnabled) {
          _playFieldGuidance('name');
        }
      }
    });
    
    _contactFocus.addListener(() {
      if (_contactFocus.hasFocus) {
        setState(() {
          _currentField = 'contact';
        });
        if (_voiceGuidanceEnabled) {
          _playFieldGuidance('contact');
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
    
    _confirmPasswordFocus.addListener(() {
      if (_confirmPasswordFocus.hasFocus) {
        setState(() {
          _currentField = 'confirm_password';
        });
        if (_voiceGuidanceEnabled) {
          _playFieldGuidance('confirm_password');
        }
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
    setState(() {
      _isLoginMode = !_isLoginMode;
      
      // Reset validation status when switching modes
      _emailValidationStatus = ValidationStatus.none;
      _passwordValidationStatus = ValidationStatus.none;
      _confirmPasswordValidationStatus = ValidationStatus.none;
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
  void _checkFieldCompletion(String field, String value) {
    bool isCompleted = false;
    
    switch (field) {
      case 'name':
        isCompleted = value.trim().isNotEmpty;
        if (isCompleted != _nameCompleted) {
          setState(() {
            _nameCompleted = isCompleted;
          });
          if (isCompleted) {
            _playFieldCompletionSound();
            _animateFieldCompletion();
          }
        }
        break;
      case 'contact':
        // Validation for email
        final emailValidator = EmailValidatorService();
        isCompleted = value.trim().isNotEmpty && emailValidator.isValidFormat(value);
        if (isCompleted != _contactCompleted) {
          setState(() {
            _contactCompleted = isCompleted;
          });
          if (isCompleted) {
            _playFieldCompletionSound();
            _animateFieldCompletion();
          }
        }
        break;
      case 'password':
        // Use password validator service for validation
        final passwordValidator = PasswordValidatorService();
        final (isPolicyValid, _) = passwordValidator.validatePolicy(value);
        isCompleted = isPolicyValid;
        if (isCompleted != _passwordCompleted) {
          setState(() {
            _passwordCompleted = isCompleted;
          });
          if (isCompleted) {
            _playFieldCompletionSound();
            _animateFieldCompletion();
          }
        }
        break;
      case 'confirm_password':
        // Check if passwords match
        isCompleted = value.trim().isNotEmpty && value == _passwordController.text;
        if (isCompleted != _confirmPasswordCompleted) {
          setState(() {
            _confirmPasswordCompleted = isCompleted;
          });
          if (isCompleted) {
            _playFieldCompletionSound();
            _animateFieldCompletion();
          }
        }
        break;
    }
  }
  
  // Animate field completion
  void _animateFieldCompletion() {
    _animationController.reset();
    _animationController.forward();
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
      return;
    }

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
  
  // Submit signup form and navigate to dashboard
  void _signup() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    // First check if the form is valid using standard validation
    if (!_signupFormKey.currentState!.validate()) {
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
                      Icons.arrow_back,
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
  
  // Build login form
  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          // Email field
          ValidatedTextField(
            label: 'Email',
            controller: _loginEmailController,
            focusNode: _loginEmailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(IconMapping.email),
            required: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_loginPasswordFocus);
            },
          ),
          const SizedBox(height: 16),
          
          // Password field
          ValidatedTextField(
            label: 'Password',
            controller: _loginPasswordController,
            focusNode: _loginPasswordFocus,
            obscureText: true,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(IconMapping.lock),
            required: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
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
                'Forgot Password?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Login button
          AppButton(
            label: 'Login',
            onPressed: _login,
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
  
  // Build signup form
  Widget _buildSignupForm() {
    return Form(
      key: _signupFormKey,
      child: Column(
        children: [
          // Name field
          AppTextField(
            controller: _nameController,
            focusNode: _nameFocus,
            label: 'Full Name',
            hint: 'Enter your full name',
            prefixIcon: const Icon(IconMapping.person),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
            onChanged: (value) {
              _checkFieldCompletion('name', value);
            },
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_contactFocus);
            },
            suffixIcon: _nameCompleted ? const Icon(IconMapping.checkCircle) : null,
          ),
          const SizedBox(height: 16),
          
          // Contact/Email field with validation
          ValidatedTextField(
            label: 'Email',
            controller: _contactController,
            focusNode: _contactFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(IconMapping.email),
            required: true,
            showValidationStatus: true,
            preventNextIfInvalid: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              
              final emailValidator = EmailValidatorService();
              if (!emailValidator.isValidFormat(value)) {
                return 'Please enter a valid email';
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
                _checkFieldCompletion('contact', value);
              });
            },
            onValidationComplete: (status) {
              // Update validation status when validation completes
              setState(() {
                _emailValidationStatus = status;
                
                // If valid, move to next field
                if (_emailValidationStatus == ValidationStatus.valid) {
                  _passwordFocus.requestFocus();
                }
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Password field with validation
          ValidatedTextField(
            label: 'Password',
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: true,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(IconMapping.lock),
            required: true,
            showValidationStatus: true,
            preventNextIfInvalid: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
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
                if (_confirmPasswordController.text.isNotEmpty) {
                  // If passwords match, set confirm password validation to valid
                  if (_confirmPasswordController.text == value) {
                    _confirmPasswordValidationStatus = ValidationStatus.valid;
                    _confirmPasswordCompleted = true;
                  } else {
                    // If passwords don't match, set confirm password validation to invalid
                    _confirmPasswordValidationStatus = ValidationStatus.invalid;
                    _confirmPasswordCompleted = false;
                  }
                  
                  // Trigger validation for confirm password field
                  _signupFormKey.currentState?.validate();
                }
              });
            },
            onValidationComplete: (status) {
              // Update validation status when validation completes
              setState(() {
                _passwordValidationStatus = status;
                
                // If valid, move to next field
                if (_passwordValidationStatus == ValidationStatus.valid) {
                  _confirmPasswordFocus.requestFocus();
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
            label: 'Confirm Password',
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocus,
            obscureText: true,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(IconMapping.lockOutline),
            required: true,
            showValidationStatus: true,
            preventNextIfInvalid: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
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
                } else if (value == _passwordController.text) {
                  _confirmPasswordValidationStatus = ValidationStatus.valid;
                  _confirmPasswordCompleted = true;
                } else {
                  _confirmPasswordValidationStatus = ValidationStatus.invalid;
                  _confirmPasswordCompleted = false;
                }
              });
            },
            onFieldSubmitted: (_) {
              if (_confirmPasswordValidationStatus == ValidationStatus.valid) {
                _signup();
              }
            },
          ),
          const SizedBox(height: 24),
          
          // Signup button
          AppButton(
            label: 'Create Account',
            onPressed: _signup,
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