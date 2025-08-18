import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savessa/core/constants/icon_mapping.dart';
import 'package:savessa/services/notifications/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Pull NotificationService from Provider (root provides it)
    final notif = Provider.of<NotificationService>(context, listen: false);

    return Scaffold(
appBar: AppBar(
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        title: const Text('Notifications'),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(IconMapping.bell),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(IconMapping.infoOutline),
              title: const Text('Push Notifications Enabled'),
              subtitle: const Text('You will receive reminders and updates.'),
              trailing: const Icon(IconMapping.chevronRight),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(IconMapping.message),
              title: const Text('Debug: Show FCM Token'),
              subtitle: Text(notif.lastToken == null ? 'Token not available yet' : 'Token ready (hidden)'),
              onTap: () async {
                final token = await notif.getToken();
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('FCM Token'),
                    content: SelectableText(token ?? 'No token'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Placeholder list of notifications
          const _NotificationItem(
            icon: IconMapping.bell,
            title: 'Contribution Reminder',
            subtitle: 'Don\'t forget to contribute GHS 500 by Friday.',
          ),
          const _NotificationItem(
            icon: IconMapping.award,
            title: 'Milestone Reached',
            subtitle: 'Your group achieved 80% of monthly target!',
          ),
          const _NotificationItem(
            icon: IconMapping.cloudSync,
            title: 'Sync Complete',
            subtitle: 'Your latest changes are safely synced.',
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _NotificationItem({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: const Icon(IconMapping.chevronRight),
        onTap: () {},
      ),
    );
  }
}

