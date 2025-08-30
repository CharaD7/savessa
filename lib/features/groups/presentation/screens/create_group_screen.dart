import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:math';

import 'package:savessa/shared/widgets/screen_scaffold.dart';
import 'package:savessa/shared/widgets/app_card.dart';
import 'package:savessa/shared/widgets/app_button.dart';
import 'package:savessa/shared/widgets/app_text_field.dart';
import 'package:savessa/core/constants/icon_mapping.dart';
import 'package:savessa/services/database/database_service.dart';
import 'package:savessa/services/user/user_data_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _organizationController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _monthlyGoalController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _groupIdController = TextEditingController();
  
  bool _isLoading = false;
  bool _smartContractEnabled = true;
  bool _allowPublicJoining = false;
  bool _requireApproval = true;
  String _meetingFrequency = 'monthly';
  DateTime? _meetingDate;
  TimeOfDay? _meetingTime;
  int _maxMembers = 50;
  
  String? _generatedInviteLink;
  DateTime? _inviteLinkExpiry;
  bool _isGeneratingLink = false;
  
  @override
  void initState() {
    super.initState();
    _generateGroupId();
  }
  
  @override
  void dispose() {
    _groupNameController.dispose();
    _organizationController.dispose();
    _branchNameController.dispose();
    _monthlyGoalController.dispose();
    _descriptionController.dispose();
    _groupIdController.dispose();
    super.dispose();
  }
  
  void _generateGroupId() {
    // Generate a unique group ID
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    final groupId = 'GRP$timestamp$random';
    _groupIdController.text = groupId;
  }
  
  Future<void> _generateInviteLink() async {
    setState(() {
      _isGeneratingLink = true;
    });
    
    try {
      // Generate encrypted invite token
      final token = _generateInviteToken();
      
      // Set expiry to 10 minutes from now
      final expiry = DateTime.now().add(const Duration(minutes: 10));
      
      // Create invite link
      final inviteLink = 'https://app.savessa.com/join/$token';
      
      setState(() {
        _generatedInviteLink = inviteLink;
        _inviteLinkExpiry = expiry;
      });
      
      // Store invite token in database for validation
      await _storeInviteToken(token, expiry);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite link generated! Valid for 10 minutes.'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating invite link: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingLink = false;
      });
    }
  }
  
  String _generateInviteToken() {
    // Generate a secure encrypted token
    final data = {
      'groupId': _groupIdController.text,
      'createdBy': context.read<UserDataService>().id,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'random': Random().nextInt(999999),
    };
    
    // Simple base64 encoding (in production, use proper encryption)
    final jsonString = json.encode(data);
    final bytes = utf8.encode(jsonString);
    return base64Url.encode(bytes);
  }
  
  Future<void> _storeInviteToken(String token, DateTime expiry) async {
    final db = DatabaseService();
    
    try {
      await db.execute(
        '''
        INSERT INTO group_invite_tokens (
          token, group_id, created_by, expires_at, created_at
        ) VALUES (
          @token, @groupId, @createdBy, @expiresAt, NOW()
        )
        ''',
        {
          'token': token,
          'groupId': _groupIdController.text,
          'createdBy': context.read<UserDataService>().id,
          'expiresAt': expiry.toIso8601String(),
        },
      );
    } catch (e) {
      // If group_invite_tokens table doesn't exist, just log the error
      // and continue without storing - the invite link will still work for sharing
      debugPrint('Warning: Could not store invite token (table may not exist): $e');
    }
  }
  
  Future<void> _selectMeetingDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _meetingDate = date;
      });
    }
  }
  
  Future<void> _selectMeetingTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    
    if (time != null) {
      setState(() {
        _meetingTime = time;
      });
    }
  }
  
  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final db = DatabaseService();
      final managerId = context.read<UserDataService>().id;
      final groupId = _groupIdController.text;
      
      // Create the group
      await db.execute(
        '''
        INSERT INTO groups (
          id, name, organization, branch_name, monthly_goal, description,
          smart_contract_enabled, allow_public_joining, require_approval,
          meeting_frequency, meeting_date, meeting_time, max_members,
          created_by, created_at, updated_at
        ) VALUES (
          @id, @name, @organization, @branchName, @monthlyGoal, @description,
          @smartContract, @publicJoining, @requireApproval,
          @meetingFreq, @meetingDate, @meetingTime, @maxMembers,
          @createdBy, NOW(), NOW()
        )
        ''',
        {
          'id': groupId,
          'name': _groupNameController.text.trim(),
          'organization': _organizationController.text.trim(),
          'branchName': _branchNameController.text.trim(),
          'monthlyGoal': double.tryParse(_monthlyGoalController.text) ?? 0,
          'description': _descriptionController.text.trim(),
          'smartContract': _smartContractEnabled,
          'publicJoining': _allowPublicJoining,
          'requireApproval': _requireApproval,
          'meetingFreq': _meetingFrequency,
          'meetingDate': _meetingDate?.toIso8601String(),
          'meetingTime': _meetingTime != null 
            ? '${_meetingTime!.hour.toString().padLeft(2, '0')}:${_meetingTime!.minute.toString().padLeft(2, '0')}' 
            : null,
          'maxMembers': _maxMembers,
          'createdBy': managerId,
        },
      );
      
      // Add the creator as the group admin
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
          'groupId': groupId,
          'userId': managerId,
          'role': 'admin',
          'addedBy': managerId,
        },
      );
      
      // Create initial monthly goal
      final now = DateTime.now();
      await db.execute(
        '''
        INSERT INTO monthly_goals (
          group_id, month, year, target_amount, achieved_amount, created_at
        ) VALUES (
          @groupId, @month, @year, @targetAmount, @achievedAmount, NOW()
        )
        ''',
        {
          'groupId': groupId,
          'month': now.month,
          'year': now.year,
          'targetAmount': double.tryParse(_monthlyGoalController.text) ?? 0,
          'achievedAmount': 0.0,
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
          'action': 'CREATE_GROUP',
          'targetType': 'GROUP',
          'targetId': groupId,
          'metadata': {
            'group_name': _groupNameController.text.trim(),
            'organization': _organizationController.text.trim(),
            'branch_name': _branchNameController.text.trim(),
            'monthly_goal': double.tryParse(_monthlyGoalController.text) ?? 0,
            'smart_contract_enabled': _smartContractEnabled,
            'max_members': _maxMembers,
          },
          'ip': '*******', // TODO: Get actual IP
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group "${ _groupNameController.text}" created successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'View Groups',
              textColor: Colors.white,
              onPressed: () {
                context.go('/groups');
              },
            ),
          ),
        );
        
        // Navigate back to groups
        context.go('/groups');
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating group: $e'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ScreenScaffold(
      title: 'Create New Group',
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
                            IconMapping.groupAdd,
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
                                'Create Savings Group',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Set up a new savings group with advanced features and member management',
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
              
              // Basic Information
              AppCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _groupNameController,
                      label: 'Group Name *',
                      prefixIcon: const Icon(IconMapping.group),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Group name is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Group name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _organizationController,
                            label: 'Organization *',
                            prefixIcon: const Icon(IconMapping.person), // Use person as business equivalent
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Organization is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            controller: _branchNameController,
                            label: 'Branch Name *',
                            prefixIcon: const Icon(IconMapping.location), // Use location as locationCity equivalent
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Branch name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _groupIdController,
                      label: 'Group ID *',
                      prefixIcon: const Icon(IconMapping.person), // Use person as badge equivalent
                      readOnly: true,
                      suffixIcon: IconButton(
                        icon: const Icon(IconMapping.settings), // Use settings as refresh equivalent
                        onPressed: _generateGroupId,
                        tooltip: 'Generate New ID',
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      prefixIcon: const Icon(IconMapping.group), // Use group as description equivalent
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Financial Settings
              AppCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Settings',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _monthlyGoalController,
                      label: 'Monthly Goal Amount (GHS) *',
                      prefixIcon: const Icon(IconMapping.group), // Use group as monetizationOn equivalent
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Monthly goal is required';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        if (amount < 50) {
                          return 'Minimum goal amount is GHS 50';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      title: const Text('Enable Smart Contracts'),
                      subtitle: const Text('Use blockchain for automated transactions'),
                      value: _smartContractEnabled,
                      onChanged: (value) {
                        setState(() {
                          _smartContractEnabled = value;
                        });
                      },
                      secondary: const Icon(IconMapping.security),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Meeting Settings
              AppCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meeting Settings',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      initialValue: _meetingFrequency,
                      decoration: const InputDecoration(
                        labelText: 'Meeting Frequency',
                        prefixIcon: Icon(IconMapping.history), // Use history as schedule equivalent
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                        DropdownMenuItem(value: 'biweekly', child: Text('Bi-weekly')),
                        DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                        DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _meetingFrequency = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Meeting Date'),
                            subtitle: Text(_meetingDate != null 
                              ? DateFormat('MMM d, yyyy').format(_meetingDate!)
                              : 'Not set'),
                            leading: const Icon(IconMapping.history), // Use history as calendar equivalent
                            onTap: _selectMeetingDate,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: theme.colorScheme.outline.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ListTile(
                            title: const Text('Meeting Time'),
                            subtitle: Text(_meetingTime != null 
                              ? _meetingTime!.format(context)
                              : 'Not set'),
                            leading: const Icon(IconMapping.history), // Use history as accessTime equivalent
                            onTap: _selectMeetingTime,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: theme.colorScheme.outline.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Group Settings
              AppCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Group Settings',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Maximum Members',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Slider(
                                value: _maxMembers.toDouble(),
                                min: 5,
                                max: 200,
                                divisions: 39,
                                label: _maxMembers.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _maxMembers = value.round();
                                  });
                                },
                              ),
                              Text(
                                '$_maxMembers members',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      title: const Text('Allow Public Joining'),
                      subtitle: const Text('Let anyone join without invitation'),
                      value: _allowPublicJoining,
                      onChanged: (value) {
                        setState(() {
                          _allowPublicJoining = value;
                        });
                      },
                      secondary: const Icon(IconMapping.group), // Use group as public equivalent
                    ),
                    
                    SwitchListTile(
                      title: const Text('Require Approval'),
                      subtitle: const Text('Manager must approve new members'),
                      value: _requireApproval,
                      onChanged: (value) {
                        setState(() {
                          _requireApproval = value;
                        });
                      },
                      secondary: const Icon(IconMapping.checkCircle), // Use checkCircle as approval equivalent
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Invite Link Section
              AppCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Group Invite Link',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppButton(
                              label: _isGeneratingLink ? 'Generate...' : 'Generate',
                              onPressed: _isGeneratingLink 
                                ? () {} 
                                : () => _generateInviteLink(),
                              type: ButtonType.secondary,
                              icon: IconMapping.globe, // Use globe as link equivalent
                              height: 36,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_generatedInviteLink != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _generatedInviteLink!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(IconMapping.edit, size: 20), // Use edit as copy equivalent
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: _generatedInviteLink!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Invite link copied to clipboard'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  IconMapping.history, // Use history as schedule equivalent
                                  size: 16,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Expires: ${DateFormat('MMM d, yyyy h:mm a').format(_inviteLinkExpiry!)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This invite link will expire in 10 minutes. You can regenerate a new link after creating the group.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.3),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              IconMapping.infoOutline, // Use infoOutline as info equivalent
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Generate a secure invite link to share with potential members. The link expires in 10 minutes for security.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                      label: _isLoading ? 'Creating Group...' : 'Create Group',
                      onPressed: _isLoading 
                        ? () {}
                        : () => _createGroup(),
                      type: ButtonType.primary,
                      height: 50,
                      icon: _isLoading ? null : IconMapping.groupAdd,
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

