import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:savessa/core/theme/app_theme.dart';
import 'package:savessa/core/constants/icon_mapping.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> with SingleTickerProviderStateMixin {
  // Track the selected role
  String? _selectedRole;
  
  // Animation controller for the selection effect
  late AnimationController _animationController;
  
  // Roles available for selection
  final List<Map<String, dynamic>> _roles = [
    {
      'id': 'admin',
      'title': 'I manage savings',
      'subtitle': 'Create and manage savings groups',
      'icon': IconMapping.settings,
      'description': 'As an admin, you can create savings groups, invite members, set contribution rules, and manage group activities.',
    },
    {
      'id': 'member',
      'title': 'I contribute savings',
      'subtitle': 'Join existing savings groups',
      'icon': IconMapping.person,
      'description': 'As a member, you can join savings groups, make contributions, track your savings, and participate in group activities.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Play selection sound (to be implemented with actual sound assets)
  void _playSelectionSound() {
    // TODO: Implement sound playback when assets are available
    debugPrint('Playing selection sound');
  }

  // Handle role selection
  void _selectRole(String roleId) {
    _playSelectionSound();
    
    setState(() {
      _selectedRole = roleId;
    });
    
    // Reset and start the animation
    _animationController.reset();
    _animationController.forward();
    
    // Navigate directly to the account setup screen
    context.go('/account-setup', extra: roleId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Choose Your Role',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select how you want to use Savessa',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Role selection cards
                Expanded(
                  child: ListView.builder(
                    itemCount: _roles.length,
                    itemBuilder: (context, index) {
                      final role = _roles[index];
                      final isSelected = _selectedRole == role['id'];
                      
                      return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          // Calculate the animation value for the selected role
                          double animValue = 0.0;
                          if (isSelected) {
                            animValue = _animationController.value;
                          }
                          
                          return GestureDetector(
                            onTap: () => _selectRole(role['id']),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.onPrimary,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? AppTheme.gold.withValues(alpha: 0.5 + (0.5 * animValue))
                                        : Colors.black.withValues(alpha: 0.1),
                                    blurRadius: isSelected ? 20 : 4,
                                    spreadRadius: isSelected ? 2 : 0,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Role icon and title row
                                  Row(
                                    children: [
                                      // Animated icon
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? theme.colorScheme.onSecondary
                                              : theme.colorScheme.primary.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Transform.scale(
                                            scale: isSelected ? 1.0 + (0.2 * animValue) : 1.0,
                                            child: Icon(
                                              role['icon'],
                                              color: isSelected
                                                  ? theme.colorScheme.secondary
                                                  : theme.colorScheme.primary,
                                              size: 30,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // Role title and subtitle
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              role['title'],
                                              style: TextStyle(
                                                color: isSelected
                                                    ? theme.colorScheme.onSecondary
                                                    : theme.colorScheme.primary,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              role['subtitle'],
                                              style: TextStyle(
                                                color: isSelected
                                                    ? theme.colorScheme.onSecondary.withValues(alpha: 0.8)
                                                    : theme.colorScheme.primary.withValues(alpha: 0.7),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Role description
                                  Text(
                                    role['description'],
                                    style: TextStyle(
                                      color: isSelected
                                          ? theme.colorScheme.onSecondary.withValues(alpha: 0.9)
                                          : theme.colorScheme.primary.withValues(alpha: 0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                
                
                // Back button
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      context.go('/onboarding');
                    },
                    icon: Icon(
                      FeatherIcons.arrowLeft,
                      color: theme.colorScheme.onPrimary,
                    ),
                    label: Text(
                      'Back to Onboarding',
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