import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:savessa/shared/widgets/app_button.dart';
import 'package:savessa/shared/widgets/app_card.dart';
import 'package:savessa/core/constants/icon_mapping.dart';
import 'package:savessa/core/theme/theme_toggle.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Logout function
  void _logout(BuildContext context) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Close the dialog
              Navigator.of(context).pop();
              
              // Navigate to login screen with default role
              context.go('/login', extra: 'member');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account settings section
            _buildSectionHeader(context, 'Account'),
            AppCard(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                children: [
                  _buildSettingItem(
                    context,
                    'Profile',
                    'Update your personal information',
                    IconMapping.profile,
                    () => context.go('/profile'),
                  ),
                  const Divider(),
                  _buildSettingItem(
                    context,
                    'Security',
                    'Change password and security settings',
                    IconMapping.lock,
                    () {},
                  ),
                  const Divider(),
                  _buildSettingItem(
                    context,
                    'Notifications',
                    'Manage your notification preferences',
                    IconMapping.notifications,
                    () => context.go('/notifications'),
                  ),
                ],
              ),
            ),
            
            // Appearance settings section
            _buildSectionHeader(context, 'Appearance'),
            AppCard(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                children: [
                  _buildSettingItem(
                    context,
                    'Theme',
                    'Change app theme',
                    Icons.color_lens,
                    () => context.go('/settings/theme'),
                    trailing: const ThemeToggleSwitch(),
                  ),
                  const Divider(),
                  _buildSettingItem(
                    context,
                    'Language',
                    'Change app language',
                    Icons.language,
                    () => context.go('/language'),
                  ),
                ],
              ),
            ),
            
            // General settings section
            _buildSectionHeader(context, 'General'),
            AppCard(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                children: [
                  _buildSettingItem(
                    context,
                    'About',
                    'About Savessa',
                    Icons.info_outline,
                    () {},
                  ),
                  const Divider(),
                  _buildSettingItem(
                    context,
                    'Help & Support',
                    'Get help with using Savessa',
                    Icons.help_outline,
                    () {},
                  ),
                  const Divider(),
                  _buildSettingItem(
                    context,
                    'Terms & Privacy',
                    'View terms of service and privacy policy',
                    Icons.policy_outlined,
                    () {},
                  ),
                ],
              ),
            ),
            
            // Logout button
            const SizedBox(height: 24),
            AppButton(
              label: 'Logout',
              onPressed: () => _logout(context),
              type: ButtonType.primary,
              isFullWidth: true,
              icon: Icons.logout,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  // Helper method to build section headers
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
  
  // Helper method to build setting items
  Widget _buildSettingItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}