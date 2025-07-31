import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../services/database/database_service.dart';

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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _otherNamesController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) {
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
      final existingUser = await dbService.getUserByEmail(userData['email']);
      if (existingUser != null) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email already registered. Please use a different email.'),
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
      backgroundColor: theme.colorScheme.background,
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
                    prefixIcon: const Icon(Icons.person),
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
                    prefixIcon: const Icon(Icons.person_outline),
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
                    prefixIcon: const Icon(Icons.people_outline),
                    // Other names is optional, so no validator
                  ),
                  const SizedBox(height: 16),
                  
                  // Email field
                  AppTextField(
                    label: 'auth.email'.tr(),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.email),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'errors.required_field'.tr();
                      }
                      if (!value.contains('@')) {
                        return 'errors.invalid_email'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone field
                  AppTextField(
                    label: 'auth.phone'.tr(),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.phone),
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
                  AppTextField(
                    label: 'auth.password'.tr(),
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.lock),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'errors.required_field'.tr();
                      }
                      if (value.length < 6) {
                        return 'errors.password_too_short'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Confirm password field
                  AppTextField(
                    label: 'auth.confirm_password'.tr(),
                    controller: _confirmPasswordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(Icons.lock_outline),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'errors.required_field'.tr();
                      }
                      if (value != _passwordController.text) {
                        return 'errors.password_mismatch'.tr();
                      }
                      return null;
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