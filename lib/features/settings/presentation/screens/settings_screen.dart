import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import 'package:savessa/shared/widgets/app_button.dart';
import 'package:savessa/shared/widgets/app_card.dart';
import 'package:savessa/core/constants/icon_mapping.dart';
import 'package:savessa/features/security/services/security_prefs_service.dart';
import 'package:savessa/shared/widgets/screen_scaffold.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _logout(BuildContext context) {
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
              Navigator.of(context).pop();
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
    return ScreenScaffold(
      title: 'Settings',
      showBackHomeFab: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  () => context.go('/settings/theme'),
                ),
                const Divider(),
                // Inline language quick picker only (no navigation)
                ListTile(
                  leading: const Icon(IconMapping.globe),
                  title: Text('Language (${_currentLanguageName(context)})'),
                  subtitle: const Text('Change app language'),
                  trailing: const SizedBox.shrink(),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: _LanguageQuickPicker(),
                ),
              ],
            ),
          ),

          _buildSectionHeader(context, 'General'),
          AppCard(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              children: [
                _buildSettingItem(
                  context,
                  'Activity Log',
                  'View your recent actions',
                  IconMapping.barChart,
                  () => context.go('/settings/audit'),
                ),
                const Divider(),
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
    );
  }

  String _currentLanguageName(BuildContext context) {
    final code = context.locale.languageCode;
    switch (code) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      case 'sw':
        return 'Kiswahili';
      case 'yo':
        return 'Yorùbá';
      case 'ha':
        return 'Hausa';
      default:
        return code;
    }
  }

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

class _LanguageQuickPicker extends StatelessWidget {
  const _LanguageQuickPicker();

  @override
  Widget build(BuildContext context) {
    final supported = context.supportedLocales;
    final current = context.locale;
    return Row(
      children: [
        const Icon(IconMapping.globe),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButton<Locale>(
            isExpanded: true,
            value: supported.contains(current) ? current : supported.first,
            items: supported
                .map(
                  (l) => DropdownMenuItem(
                    value: l,
                    child: Text(_nameFor(l.languageCode)),
                  ),
                )
                .toList(),
            onChanged: (l) async {
              if (l == null) return;
              await context.setLocale(l);
            },
          ),
        ),
      ],
    );
  }

  String _nameFor(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      case 'sw':
        return 'Kiswahili';
      case 'yo':
        return 'Yorùbá';
      case 'ha':
        return 'Hausa';
      default:
        return code;
    }
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
