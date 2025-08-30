import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';

// Core architecture imports
import 'package:savessa/core/models/models.dart';
import 'package:savessa/core/repositories/repositories.dart';
import 'package:savessa/services/database/database_service.dart';
import 'package:savessa/services/user/user_data_service.dart';
import 'package:savessa/services/groups/active_group_service.dart';

// UI components
import 'package:savessa/shared/widgets/screen_scaffold.dart';
import 'package:savessa/shared/widgets/app_card.dart';
import 'package:savessa/shared/widgets/app_button.dart';
import 'package:savessa/shared/widgets/profile_avatar.dart';
import 'package:savessa/core/constants/icon_mapping.dart';
import 'package:savessa/core/theme/app_theme.dart';

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen> 
    with SingleTickerProviderStateMixin {
  
  // Repositories
  late final UserRepository _userRepository;
  late final GroupRepository _groupRepository;
  late final ContributionRepository _contributionRepository;
  
  // Animation controllers
  late AnimationController _animationController;
  late ConfettiController _confettiController;
  
  // State variables
  UserModel? _currentUser;
  List<GroupWithMetadata> _userGroups = [];
  GroupWithMetadata? _activeGroup;
  List<ContributionModel> _recentContributions = [];
  ContributionStatsModel? _stats;
  bool _isLoading = true;
  bool _showMilestoneCelebration = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    
    // Initialize repositories
    _initializeRepositories();
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _initializeRepositories() {
    final databaseService = DatabaseService();
    _userRepository = DatabaseUserRepository(databaseService);
    _groupRepository = DatabaseGroupRepository(databaseService);
    _contributionRepository = DatabaseContributionRepository(databaseService);
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get current user from UserDataService
      final userDataService = context.read<UserDataService>();
      final userId = userDataService.id;
      
      if (userId == null) {
        throw Exception('User not found');
      }

      // Load user details
      _currentUser = await _userRepository.getUserById(userId);
      
      if (_currentUser == null) {
        throw Exception('User details not found');
      }

      // Load user's groups with metadata
      _userGroups = await _groupRepository.getGroupsWithMetadataForUser(userId);
      
      // Set active group (get from ActiveGroupService or use first group)
      try {
        final activeGroupService = context.read<ActiveGroupService>();
        final activeGroupId = activeGroupService.groupId;
        
        if (activeGroupId != null) {
          _activeGroup = _userGroups.firstWhere(
            (group) => group.group.id == activeGroupId,
            orElse: () => _userGroups.isNotEmpty ? _userGroups.first : throw Exception('No active group'),
          );
        } else if (_userGroups.isNotEmpty) {
          _activeGroup = _userGroups.first;
          activeGroupService.setActive(_activeGroup!.group.id, _activeGroup!.group.name);
        }
      } catch (_) {
        if (_userGroups.isNotEmpty) {
          _activeGroup = _userGroups.first;
        }
      }

      // Load recent contributions for active group
      if (_activeGroup != null) {
        _recentContributions = await _contributionRepository.getRecentContributions(
          groupId: _activeGroup!.group.id,
          limit: 10,
          includeUser: true,
        );

        // Load contribution statistics
        _stats = await _contributionRepository.getContributionStats(
          groupId: _activeGroup!.group.id,
          userId: userId,
        );
      }

      // Check for milestone achievements and trigger celebration
      _checkForMilestones();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _checkForMilestones() {
    if (_activeGroup?.currentGoal != null) {
      final progress = _activeGroup!.currentGoal!.progress;
      
      // Check for milestone achievements (50%, 75%, 100%)
      if (progress >= 0.5 && progress < 0.6) {
        _triggerMilestoneCelebration('50% of your monthly goal reached! 🎉');
      } else if (progress >= 0.75 && progress < 0.85) {
        _triggerMilestoneCelebration('75% of your monthly goal reached! 🚀');
      } else if (progress >= 1.0) {
        _triggerMilestoneCelebration('Monthly goal achieved! Congratulations! 🏆');
      }
    }
  }

  void _triggerMilestoneCelebration(String message) {
    setState(() {
      _showMilestoneCelebration = true;
    });
    
    _animationController.forward();
    _confettiController.play();
    
    // Auto-hide after animation
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showMilestoneCelebration = false;
        });
        _animationController.reset();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ScreenScaffold(
      title: 'home.title'.tr(),
      actions: [
        // Profile avatar button
        if (_currentUser != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ProfileAvatar(
              profileImageUrl: _currentUser!.profileImageUrl,
              firstName: _currentUser!.firstName,
              lastName: _currentUser!.lastName,
              radius: 18,
              onTap: () => context.go('/profile'),
              showBorder: true,
            ),
          ),
        IconButton(
          icon: const Icon(IconMapping.refresh),
          onPressed: _isLoading ? null : _loadInitialData,
        ),
        IconButton(
          icon: const Icon(IconMapping.notifications),
          onPressed: () => context.go('/notifications'),
        ),
        IconButton(
          icon: const Icon(IconMapping.settings),
          onPressed: () => context.go('/settings'),
        ),
      ],
      body: Stack(
        children: [
          // Main content
          _buildMainContent(theme),
          
          // Milestone celebration overlay
          if (_showMilestoneCelebration)
            _buildMilestoneCelebration(theme),
            
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              maxBlastForce: 25,
              minBlastForce: 10,
              colors: const [AppTheme.gold, Colors.white, AppTheme.royalPurple],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your dashboard...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconMapping.error,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load dashboard',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Retry',
              onPressed: _loadInitialData,
              type: ButtonType.primary,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            _buildWelcomeHeader(theme),
            const SizedBox(height: 24),
            
            // Total savings card
            _buildTotalSavingsCard(theme),
            const SizedBox(height: 24),
            
            // Monthly progress card
            if (_activeGroup?.currentGoal != null)
              _buildMonthlyProgressCard(theme),
            const SizedBox(height: 24),
            
            // Quick actions
            _buildQuickActions(theme),
            const SizedBox(height: 24),
            
            // Recent activities
            _buildRecentActivities(theme),
            const SizedBox(height: 24),
            
            // Groups overview
            _buildGroupsOverview(theme),
            const SizedBox(height: 24),
            
            // Statistics summary
            if (_stats != null)
              _buildStatisticsSummary(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(ThemeData theme) {
    final displayName = _currentUser?.displayName ?? 'User';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${'home.welcome'.tr()}, $displayName!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_activeGroup != null)
          Text(
            'Active Group: ${_activeGroup!.group.name}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
      ],
    );
  }

  Widget _buildTotalSavingsCard(ThemeData theme) {
    final totalSavings = _userGroups.fold<double>(
      0.0, 
      (sum, group) => sum + group.totalSaved,
    );
    
    final currentMonthSavings = _userGroups.fold<double>(
      0.0, 
      (sum, group) => sum + group.currentMonthSaved,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: AppGradientCard(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              padding: const EdgeInsets.all(24.0),
              title: 'home.total_savings'.tr(),
              trailing: IconButton(
                icon: const Icon(IconMapping.infoOutline, color: Colors.white),
                onPressed: () => _showTotalSavingsInfo(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: totalSavings),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedValue, child) {
                      return Text(
                        'GHS ${animatedValue.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSavingsMetric(
                        theme,
                        'home.this_month'.tr(),
                        'GHS ${currentMonthSavings.toStringAsFixed(2)}',
                      ),
                      _buildSavingsMetric(
                        theme,
                        'Groups',
                        '${_userGroups.length}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavingsMetric(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyProgressCard(ThemeData theme) {
    final goal = _activeGroup!.currentGoal!;
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: AppCard(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${goal.monthName} ${goal.year} Goal',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        goal.isAchieved ? IconMapping.award : IconMapping.target,
                        color: goal.isAchieved ? AppTheme.gold : theme.colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress bar with animation
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: goal.progress),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedProgress, child) {
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(goal.formattedAchievedAmount),
                              Text(
                                '${(animatedProgress * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: goal.isAchieved ? AppTheme.gold : theme.colorScheme.primary,
                                ),
                              ),
                              Text(goal.formattedTargetAmount),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Stack(
                            children: [
                              Container(
                                height: 12,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              Container(
                                height: 12,
                                width: MediaQuery.of(context).size.width * 0.8 * animatedProgress,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: goal.isAchieved
                                        ? [AppTheme.gold, AppTheme.gold.withOpacity(0.7)]
                                        : [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  if (!goal.isAchieved)
                    Text(
                      '${goal.formattedRemainingAmount} remaining',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    )
                  else
                    Row(
                      children: [
                        const Icon(IconMapping.checkCircle, color: AppTheme.gold, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Goal achieved!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'home.quick_actions'.tr(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                theme,
                IconMapping.addCircle,
                'home.add_savings'.tr(),
                () => context.go('/savings/add'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                theme,
                IconMapping.analytics,
                'Analytics',
                () => context.go('/analytics'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                theme,
                IconMapping.groupAdd,
                'Groups',
                () => context.go('/groups'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                theme,
                IconMapping.person,
                'Profile',
                () => context.go('/profile'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(ThemeData theme, IconData icon, String title, VoidCallback onTap) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: AppCard(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivities(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'home.recent_activities'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/savings/history'),
              child: Text('home.view_all'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_recentContributions.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    IconMapping.history,
                    size: 48,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recent contributions yet',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start saving to see your activity here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: _recentContributions.take(5).map((contribution) {
                return _buildActivityItem(theme, contribution);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildActivityItem(ThemeData theme, ContributionModel contribution) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              IconMapping.savings,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contribution to ${contribution.groupName}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contribution.formattedDate,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            contribution.formattedAmount,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsOverview(ThemeData theme) {
    if (_userGroups.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Groups',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _userGroups.length,
            itemBuilder: (context, index) {
              final groupMeta = _userGroups[index];
              return _buildGroupCard(theme, groupMeta, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(ThemeData theme, GroupWithMetadata groupMeta, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 800 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 200,
            margin: const EdgeInsets.only(right: 16),
            child: AppCard(
              onTap: () {
                // Set as active group and navigate
                context.read<ActiveGroupService>().setActive(groupMeta.group.id, groupMeta.group.name);
                context.go('/groups/${groupMeta.group.id}');
              },
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          groupMeta.group.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (groupMeta.group.smartContractEnabled)
                        const Icon(
                          IconMapping.security,
                          size: 16,
                          color: AppTheme.gold,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    groupMeta.formattedTotalSaved,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${groupMeta.memberCount} members',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (groupMeta.currentGoal != null)
                        Text(
                          groupMeta.currentGoal!.progressPercentage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  
                  // Progress indicator if there's a current goal
                  if (groupMeta.currentGoal != null) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: groupMeta.currentGoal!.progress,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                      minHeight: 4,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsSummary(ThemeData theme) {
    final stats = _stats!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Statistics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                'Total Contributions',
                '${stats.totalCount}',
                IconMapping.count,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                theme,
                'Average Amount',
                stats.formattedAverageAmount,
                IconMapping.analytics,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme, String title, String value, IconData icon) {
    return AppCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCelebration(ThemeData theme) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.7 * _animationController.value),
          child: Center(
            child: Transform.scale(
              scale: _animationController.value,
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      IconMapping.award,
                      size: 80,
                      color: AppTheme.gold,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Congratulations!',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You\'ve reached a new milestone!',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: 'Continue',
                      onPressed: () {
                        setState(() {
                          _showMilestoneCelebration = false;
                        });
                        _animationController.reset();
                      },
                      type: ButtonType.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTotalSavingsInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Total Savings Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This shows the sum of all your contributions across all groups.'),
            const SizedBox(height: 16),
            if (_userGroups.isNotEmpty) ...[
              Text('Group breakdown:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._userGroups.map((group) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(group.group.name)),
                    Text(group.formattedTotalSaved),
                  ],
                ),
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
