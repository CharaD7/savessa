import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:savessa/shared/widgets/app_button.dart';
import 'package:savessa/shared/widgets/app_card.dart';
import 'package:savessa/core/constants/icon_mapping.dart';
// import 'package:savessa/core/theme/theme_toggle.dart';
import 'package:provider/provider.dart';
import 'package:savessa/features/security/services/security_prefs_service.dart';

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
              
              // Navigate back to account setup screen in login mode
              context.go('/account-setup', extra: 'login');
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
        automaticallyImplyLeading: Navigator.of(context).canPop(),
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
                    () => context.go('/settings/two-factor'),
                  ),
                  const Divider(),
                  // Biometric requirement toggle inline
                  _BiometricRequirementTile(),
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
                    IconMapping.droplet,
() => context.go('/settings/theme')
                  ),
                  const Divider(),
_buildSettingItem(
                    context,
                    'Language',
                    'Change app language',
                    IconMapping.globe,
() => context.go('/language')
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
                    IconMapping.infoOutline,
                    () {},
                  ),
                  const Divider(),
_buildSettingItem(
                    context,
                    'Help \u0026 Support',
                    'Get help with using Savessa',
                    IconMapping.infoOutline,
                    () {},
                  ),
                  const Divider(),
_buildSettingItem(
                    context,
                    'Terms \u0026 Privacy',
                    'View terms of service and privacy policy',
                    IconMapping.infoOutline,
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
trailing: trailing ?? const Icon(IconMapping.chevronRight),
      onTap: onTap,
    );
  }
}

class _BiometricRequirementTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityPrefsService>(
      builder: (context, prefs, _) {
        return SwitchListTile(
          secondary: const Icon(IconMapping.lock),
          title: const Text('Require biometrics for sensitive actions'),
          subtitle: const Text('Ask for Face/Touch ID before risky operations'),
          value: prefs.requireBiometric,
          onChanged: (v) => prefs.setRequireBiometric(v),
        );
      },
    );
  }
}
