import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:savessa/shared/widgets/screen_scaffold.dart';

import 'package:savessa/shared/widgets/app_card.dart';
import 'package:savessa/shared/widgets/app_button.dart';
import 'package:savessa/core/constants/icon_mapping.dart';
import 'package:savessa/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:savessa/services/sync/sync_service.dart';
import 'package:savessa/services/sync/queue_store.dart';
import 'package:savessa/services/user/user_data_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // Animation controller for milestone celebrations
  late AnimationController _animationController;
  
  // Flag to show milestone celebration
  bool _showMilestoneCelebration = false;
  
  // Selected date in calendar
  DateTime _selectedDate = DateTime.now();
  
  // Mock data for savings goals
  final List<Map<String, dynamic>> _savingsGoals = [
    {
      'name': 'Emergency Fund',
      'current': 3000,
      'target': 5000,
      'color': Colors.blue,
    },
    {
      'name': 'Home Renovation',
      'current': 7500,
      'target': 15000,
      'color': Colors.green,
    },
    {
      'name': 'Education',
      'current': 2000,
      'target': 10000,
      'color': Colors.orange,
    },
  ];
  
  // Mock data for calendar contributions
  final Map<DateTime, double> _contributionsByDate = {
    DateTime(2025, 7, 5): 500,
    DateTime(2025, 7, 12): 200,
    DateTime(2025, 7, 19): 300,
    DateTime(2025, 7, 26): 500,
    DateTime(2025, 8, 2): 500,
  };
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    // Show milestone celebration after a short delay (for demo purposes)
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _showMilestoneCelebration = true;
      });
      _animationController.forward();
      
      // Hide celebration after animation completes
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() {
          _showMilestoneCelebration = false;
        });
      });
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Check if a date has a contribution
  bool _hasContribution(DateTime date) {
    return _contributionsByDate.keys.any((d) => 
      d.year == date.year && d.month == date.month && d.day == date.day);
  }
  
  // Get contribution amount for a date
  double _getContributionAmount(DateTime date) {
    for (final d in _contributionsByDate.keys) {
      if (d.year == date.year && d.month == date.month && d.day == date.day) {
        return _contributionsByDate[d]!;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ScreenScaffold(
      title: 'home.title'.tr(),
      actions: [
          // Sync status chip
          Builder(builder: (context) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _HomeSyncChip(),
            );
          }),
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
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome message
                  Text(
'${'home.welcome'.tr()}, ${context.select<UserDataService, String>((s) => s.firstName.isNotEmpty ? s.firstName : 'User')}!',
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
                                color: Colors.white.withValues(alpha: 0.8),
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
                                color: Colors.white.withValues(alpha: 0.8),
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
                    child: Builder(
                      builder: (context) {
                        final role = context.read<UserDataService>().role;
                        final disabled = role == 'admin';
                        return Opacity(
                          opacity: disabled ? 0.5 : 1.0,
                          child: _buildQuickActionCard(
                            context,
                            IconMapping.groupAdd,
                            'home.join_group'.tr(),
                            () {
                              if (disabled) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Savings Managers cannot join groups. You can create and manage groups.'),
                                    backgroundColor: Theme.of(context).colorScheme.error,
                                  ),
                                );
                                return;
                              }
                              context.go('/groups');
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      IconMapping.addBox,
                      'home.create_group'.tr(),
() {
                        final role = context.read<UserDataService>().role;
                        if (role != 'admin') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Only Savings Managers can create groups. You can join existing groups.'),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                          );
                          return;
                        }
                        context.go('/groups/create');
                      },
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
              
              // Savings Goals with Progress Bars
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Savings Goals',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              
              AppCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: _savingsGoals.map((goal) {
                    final progress = goal['current'] / goal['target'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                goal['name'],
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: goal['color'],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Animated progress bar
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Stack(
                                children: [
                                  // Background
                                  Container(
                                    height: 12,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  // Progress
                                  Container(
                                    height: 12,
                                    width: MediaQuery.of(context).size.width * 0.8 * value,
                                    decoration: BoxDecoration(
                                      color: goal['color'],
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: goal['color'].withValues(alpha: 0.4),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'GHS ${goal['current'].toStringAsFixed(2)}',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                'GHS ${goal['target'].toStringAsFixed(2)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              // Calendar View
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Contribution Calendar',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              
              AppCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Month and year header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
IconButton(
                        icon: const Icon(IconMapping.chevronLeft),
                        onPressed: () {
                            setState(() {
                              _selectedDate = DateTime(
                                _selectedDate.year,
                                _selectedDate.month - 1,
                                _selectedDate.day,
                              );
                            });
                          },
                        ),
                        Text(
                          DateFormat('MMMM yyyy').format(_selectedDate),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
IconButton(
                        icon: const Icon(IconMapping.chevronRight),
                        onPressed: () {
                            setState(() {
                              _selectedDate = DateTime(
                                _selectedDate.year,
                                _selectedDate.month + 1,
                                _selectedDate.day,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Calendar grid
                    _buildCalendarGrid(context),
                    
                    const SizedBox(height: 16),
                    
                    // Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCalendarLegendItem(
                          context,
                          'No Contribution',
                          theme.colorScheme.surfaceContainerHighest,
                        ),
                        const SizedBox(width: 16),
                        _buildCalendarLegendItem(
                          context,
                          'Contribution Made',
                          theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
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
          
          // Milestone celebration overlay
          if (_showMilestoneCelebration)
            Positioned.fill(
              child: Stack(
                children: [
                  // Semi-transparent background
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                  
                  // Celebration content
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Lottie animation placeholder (replace with actual animation)
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.gold.withValues(alpha: 0.2),
                          ),
child: const Center(
                            child: Icon(
                              IconMapping.award,
                              size: 100,
                              color: AppTheme.gold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Congratulations!',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'ve reached 50% of your savings goal!',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showMilestoneCelebration = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.gold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: const Text('Continue'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
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
              color: iconColor.withValues(alpha: 0.1),
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
  
  // Build calendar grid
  Widget _buildCalendarGrid(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month + 1,
      0,
    ).day;
    
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final firstWeekdayOfMonth = firstDayOfMonth.weekday % 7; // 0 = Sunday, 6 = Saturday
    
    // Days of the week header
    final daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    return Column(
      children: [
        // Days of week header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: daysOfWeek.map((day) {
            return SizedBox(
              width: 32,
              child: Text(
                day,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        
        // Calendar days grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: (firstWeekdayOfMonth + daysInMonth),
          itemBuilder: (context, index) {
            // Empty cells before the first day of the month
            if (index < firstWeekdayOfMonth) {
              return const SizedBox();
            }
            
            final day = index - firstWeekdayOfMonth + 1;
            final date = DateTime(_selectedDate.year, _selectedDate.month, day);
            final hasContribution = _hasContribution(date);
            final isToday = DateTime.now().year == date.year &&
                           DateTime.now().month == date.month &&
                           DateTime.now().day == date.day;
            
            return GestureDetector(
              onTap: () {
                if (hasContribution) {
                  // Show contribution details with animation
                  final amount = _getContributionAmount(date);
                  
                  // Animated feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Contribution on ${DateFormat('MMM d').format(date)}: GHS $amount'),
                      backgroundColor: theme.colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: 'View Details',
                        textColor: theme.colorScheme.onPrimary,
                        onPressed: () {
                          // Navigate to contribution details
                        },
                      ),
                    ),
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: hasContribution
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(
                          color: theme.colorScheme.secondary,
                          width: 2,
                        )
                      : null,
                ),
                child: Center(
                  child: Text(
                    day.toString(),
                    style: TextStyle(
                      color: hasContribution
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  // Build calendar legend item
  Widget _buildCalendarLegendItem(BuildContext context, String label, Color color) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
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
            // Animated button with feedback
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: AppButton(
                    label: 'home.pay_now'.tr(),
                    onPressed: () {
                      // Provide haptic feedback
                      HapticFeedback.mediumImpact();
                      
                      // Animate button press
                      setState(() {
                        // This will be handled by the TweenAnimationBuilder
                      });
                      
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
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeSyncChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    try {
      final sync = Provider.of<SyncService>(context, listen: false);
      return ValueListenableBuilder<SyncState>(
        valueListenable: sync.stateNotifier,
        builder: (context, s, _) {
          final (icon, color, label) = switch (s) {
            SyncState.syncing => (Icons.cloud_sync, Theme.of(context).colorScheme.primary, 'Syncing'),
            SyncState.error => (Icons.cloud_off, Theme.of(context).colorScheme.error, 'Sync Error'),
            _ => (Icons.cloud_done, Colors.green, 'Synced'),
          };
final qs = Provider.of<QueueStore>(context, listen: false);
          return Chip(
            avatar: Icon(icon, color: color, size: 18),
            label: Text('$label${qs.pendingCount > 0 ? ' (${qs.pendingCount})' : ''}', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            backgroundColor: color.withValues(alpha: 0.08),
            shape: StadiumBorder(side: BorderSide(color: color.withValues(alpha: 0.3))),
          );
        },
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
