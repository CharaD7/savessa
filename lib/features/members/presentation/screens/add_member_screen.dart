import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:savessa/shared/widgets/screen_scaffold.dart';
import 'package:savessa/shared/widgets/app_card.dart';
import 'package:savessa/shared/widgets/app_button.dart';
import 'package:savessa/shared/widgets/app_text_field.dart';
import 'package:savessa/core/constants/icon_mapping.dart';
import 'package:savessa/services/database/database_service.dart';
import 'package:savessa/services/user/user_data_service.dart';

class AddMemberScreen extends StatefulWidget {
  final String? groupId;
  
  const AddMemberScreen({super.key, this.groupId});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _occupationController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  
  String? _selectedGroupId;
  String _selectedRole = 'member';
  bool _isLoading = false;
  bool _sendWelcomeEmailEnabled = true;
  bool _sendWelcomeSMSEnabled = true;
  
  final List<Map<String, dynamic>> _availableGroups = [];
  
  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.groupId;
    _loadAvailableGroups();
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _idNumberController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAvailableGroups() async {
    try {
      // Fetch groups created by current manager
      final userId = context.read<UserDataService>().id;
      final db = DatabaseService();
      
      final groups = await db.query(
        'SELECT id, name FROM groups WHERE created_by = @uid ORDER BY name',
        {'uid': userId},
      );
      
      setState(() {
        _availableGroups.clear();
        _availableGroups.addAll(groups.map((g) => {
          'id': g['id'] as String,
          'name': g['name'] as String,
        }));
      });
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading groups: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
  
  Future<void> _addMember() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedGroupId == null || _selectedGroupId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a group for the member'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final db = DatabaseService();
      final managerId = context.read<UserDataService>().id;
      
      // Generate unique member ID
      final memberId = 'MBR${DateTime.now().millisecondsSinceEpoch}';
      
      // Generate temporary password
      final tempPassword = _generateTempPassword();
      
      // Create user account
      final userId = await db.execute(
        '''
        INSERT INTO users (
          id, first_name, last_name, email, phone, role, 
          id_number, address, occupation, created_at, updated_at
        ) VALUES (
          @id, @firstName, @lastName, @email, @phone, @role,
          @idNumber, @address, @occupation, NOW(), NOW()
        ) RETURNING id
        ''',
        {
          'id': memberId,
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': _selectedRole,
          'idNumber': _idNumberController.text.trim(),
          'address': _addressController.text.trim(),
          'occupation': _occupationController.text.trim(),
        },
      );
      
      // Add member to group
      await db.execute(
        '''
        INSERT INTO group_members (
          id, group_id, user_id, role, joined_at, added_by
        ) VALUES (
          @id, @groupId, @userId, @role, NOW(), @addedBy
        )
        ''',
        {
          'id': 'GM${DateTime.now().millisecondsSinceEpoch}',
          'groupId': _selectedGroupId,
          'userId': memberId,
          'role': _selectedRole,
          'addedBy': managerId,
        },
      );
      
      // Create member profile
      await db.execute(
        '''
        INSERT INTO member_profiles (
          user_id, emergency_contact, emergency_phone, created_at, updated_at
        ) VALUES (
          @userId, @emergencyContact, @emergencyPhone, NOW(), NOW()
        )
        ''',
        {
          'userId': memberId,
          'emergencyContact': _emergencyContactController.text.trim(),
          'emergencyPhone': _emergencyPhoneController.text.trim(),
        },
      );
      
      // Create audit log
      await db.execute(
        '''
        INSERT INTO admin_audit_log (
          user_id, action, target_type, target_id, metadata, ip
        ) VALUES (
          @userId, @action, @targetType, @targetId, @metadata::jsonb, @ip
        )
        ''',
        {
          'userId': managerId,
          'action': 'CREATE_MEMBER',
          'targetType': 'USER',
          'targetId': memberId,
          'metadata': {
            'member_name': '${_firstNameController.text} ${_lastNameController.text}',
            'group_id': _selectedGroupId,
            'role': _selectedRole,
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
          },
          'ip': '*******', // TODO: Get actual IP
        },
      );
      
      // TODO: Send welcome email and SMS if enabled
      if (_sendWelcomeEmailEnabled) {
        await _sendWelcomeEmailMessage(
          _emailController.text.trim(),
          '${_firstNameController.text} ${_lastNameController.text}',
          tempPassword,
        );
      }
      
      if (_sendWelcomeSMSEnabled) {
        await _sendWelcomeSMSMessage(
          _phoneController.text.trim(),
          '${_firstNameController.text} ${_lastNameController.text}',
          tempPassword,
        );
      }
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Member added successfully! Member ID: $memberId'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Copy ID',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: memberId));
              },
            ),
          ),
        );
        
        // Navigate back
        context.pop();
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding member: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
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
  
  String _generateTempPassword() {
    // Generate a secure temporary password
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = DateTime.now().millisecondsSinceEpoch;
    return String.fromCharCodes(List.generate(12, (index) => 
      chars.codeUnitAt((random + index) % chars.length)
    ));
  }
  
  Future<void> _sendWelcomeEmailMessage(String email, String name, String password) async {
    // TODO: Implement email sending
    print('Sending welcome email to $email for $name with password: $password');
  }
  
  Future<void> _sendWelcomeSMSMessage(String phone, String name, String password) async {
    // TODO: Implement SMS sending
    print('Sending welcome SMS to $phone for $name with password: $password');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ScreenScaffold(
      title: 'Add New Member',
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              AppCard(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            IconMapping.groupAdd, // Use groupAdd as personAdd equivalent
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add New Member',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fill in the member details to add them to your savings group',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Group Selection
              AppCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Group Assignment',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGroupId,
                      decoration: const InputDecoration(
                        labelText: 'Select Group *',
                        prefixIcon: Icon(IconMapping.group),
                        border: OutlineInputBorder(),
                      ),
                      items: _availableGroups.map((group) {
                        return DropdownMenuItem<String>(
                          value: group['id'],
                          child: Text(group['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGroupId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a group';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Member Role *',
                        prefixIcon: Icon(IconMapping.security),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'member', child: Text('Member')),
                        DropdownMenuItem(value: 'treasurer', child: Text('Treasurer')),
                        DropdownMenuItem(value: 'secretary', child: Text('Secretary')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Personal Information
              AppCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Information',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _firstNameController,
                            label: 'First Name *',
                            prefixIcon: const Icon(IconMapping.person),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'First name is required';
                              }
                              if (value.trim().length < 2) {
                                return 'First name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            controller: _lastNameController,
                            label: 'Last Name *',
                            prefixIcon: const Icon(IconMapping.person),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Last name is required';
                              }
                              if (value.trim().length < 2) {
                                return 'Last name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _emailController,
                      label: 'Email Address *',
                      prefixIcon: const Icon(IconMapping.email),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _phoneController,
                      label: 'Phone Number *',
                      prefixIcon: const Icon(IconMapping.phone),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        if (value.trim().length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _idNumberController,
                      label: 'ID Number',
                      prefixIcon: const Icon(IconMapping.person), // Use person as badge equivalent
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty && value.trim().length < 8) {
                          return 'ID number must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Additional Information
              AppCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Information',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _addressController,
                      label: 'Address',
                      prefixIcon: const Icon(IconMapping.location),
                      maxLines: 2,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _occupationController,
                      label: 'Occupation',
                      prefixIcon: const Icon(IconMapping.person), // Use person as work equivalent
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Emergency Contact
              AppCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Contact',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _emergencyContactController,
                      label: 'Emergency Contact Name',
                      prefixIcon: const Icon(IconMapping.person), // Use person for contact
                    ),
                    
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _emergencyPhoneController,
                      label: 'Emergency Contact Phone',
                      prefixIcon: const Icon(IconMapping.phone),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Notification Settings
              AppCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Notifications',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      title: const Text('Send Welcome Email'),
                      subtitle: const Text('Send login credentials via email'),
                      value: _sendWelcomeEmailEnabled,
                      onChanged: (value) {
                        setState(() {
                          _sendWelcomeEmailEnabled = value;
                        });
                      },
                      secondary: const Icon(IconMapping.email),
                    ),
                    
                    SwitchListTile(
                      title: const Text('Send Welcome SMS'),
                      subtitle: const Text('Send login credentials via SMS'),
                      value: _sendWelcomeSMSEnabled,
                      onChanged: (value) {
                        setState(() {
                          _sendWelcomeSMSEnabled = value;
                        });
                      },
                      secondary: const Icon(IconMapping.message), // Use message as SMS equivalent
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      onPressed: _isLoading 
                        ? () {}
                        : () => context.pop(),
                      type: ButtonType.secondary,
                      height: 50,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: _isLoading ? 'Adding Member...' : 'Add Member',
                      onPressed: _isLoading 
                        ? () {}
                        : () => _addMember(),
                      type: ButtonType.primary,
                      height: 50,
                      icon: _isLoading ? null : IconMapping.groupAdd, // Use groupAdd as personAdd equivalent
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
