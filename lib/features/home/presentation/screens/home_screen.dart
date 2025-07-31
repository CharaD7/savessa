import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../core/constants/icon_mapping.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('home.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(IconMapping.notifications),
            onPressed: () {
              context.go('/notifications');
            },
          ),
          IconButton(
            icon: const Icon(IconMapping.settings),
            onPressed: () {
              context.go('/settings');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Text(
                '${'home.welcome'.tr()}, User!',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              
              // Total savings card
              AppGradientCard(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                padding: const EdgeInsets.all(20.0),
                margin: const EdgeInsets.only(bottom: 16.0),
                title: 'home.total_savings'.tr(),
                trailing: IconButton(
                  icon: const Icon(IconMapping.infoOutline, color: Colors.white),
                  onPressed: () {
                    // Show info about total savings
                  },
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'GHS 5,000.00',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'home.this_month'.tr(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              'GHS 500.00',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'home.all_time'.tr(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              'GHS 12,500.00',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Quick actions
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'home.quick_actions'.tr(),
                  style: theme.textTheme.titleLarge,
                ),
              ),
              
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      IconMapping.addCircle,
                      'home.add_savings'.tr(),
                      () => context.go('/savings/add'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      IconMapping.history,
                      'home.view_history'.tr(),
                      () => context.go('/savings/history'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      IconMapping.groupAdd,
                      'home.join_group'.tr(),
                      () => context.go('/groups'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      IconMapping.addBox,
                      'home.create_group'.tr(),
                      () => context.go('/groups/create'),
                    ),
                  ),
                ],
              ),
              
              // Recent activities
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'home.recent_activities'.tr(),
                      style: theme.textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        context.go('/savings/history');
                      },
                      child: Text('home.view_all'.tr()),
                    ),
                  ],
                ),
              ),
              
              // Activity list
              _buildActivityItem(
                context,
                'Monthly Contribution',
                'GHS 500.00',
                DateTime.now().subtract(const Duration(days: 2)),
                IconMapping.arrowUpward,
                Colors.green,
              ),
              _buildActivityItem(
                context,
                'Group Savings - Family',
                'GHS 200.00',
                DateTime.now().subtract(const Duration(days: 5)),
                IconMapping.arrowUpward,
                Colors.green,
              ),
              _buildActivityItem(
                context,
                'Withdrawal',
                'GHS 1,000.00',
                DateTime.now().subtract(const Duration(days: 15)),
                IconMapping.arrowDownward,
                Colors.red,
              ),
              
              // Upcoming payments
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'home.upcoming_payments'.tr(),
                  style: theme.textTheme.titleLarge,
                ),
              ),
              
              AppCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildUpcomingPayment(
                      context,
                      'Monthly Contribution',
                      'GHS 500.00',
                      DateTime.now().add(const Duration(days: 5)),
                    ),
                    const Divider(),
                    _buildUpcomingPayment(
                      context,
                      'Group Savings - Family',
                      'GHS 200.00',
                      DateTime.now().add(const Duration(days: 10)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuickActionCard(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivityItem(
    BuildContext context,
    String title,
    String amount,
    DateTime date,
    IconData icon,
    Color iconColor,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dateFormat.format(date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUpcomingPayment(
    BuildContext context,
    String title,
    String amount,
    DateTime dueDate,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${'home.due_date'.tr()}: ',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    dateFormat.format(dueDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            AppButton(
              label: 'home.pay_now'.tr(),
              onPressed: () {
                // Navigate to payment screen
                context.go('/payments');
              },
              type: ButtonType.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              height: 32,
            ),
          ],
        ),
      ],
    );
  }
}