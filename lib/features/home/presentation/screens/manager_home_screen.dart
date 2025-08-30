import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:savessa/core/theme/app_theme.dart';
import 'package:savessa/shared/widgets/app_card.dart';
import 'package:provider/provider.dart';
import 'package:savessa/services/auth/auth_service.dart';
import 'package:savessa/services/groups/group_service.dart';
import 'package:savessa/services/groups/contribution_service.dart';
import 'package:savessa/services/groups/member_service.dart';
import 'package:savessa/services/audit/audit_log_service.dart';
import 'package:savessa/services/sms/sms_service.dart';
import 'package:savessa/services/sync/sync_service.dart';
import 'package:savessa/services/sync/queue_store.dart';
import 'package:savessa/features/security/services/biometric_service.dart';
import 'package:savessa/core/constants/icon_mapping.dart';
import 'package:savessa/features/security/services/security_prefs_service.dart';
import 'package:savessa/features/manager/services/contract_service_mock.dart';
import 'package:go_router/go_router.dart';
import 'package:savessa/services/user/user_data_service.dart';
import 'package:savessa/shared/widgets/profile_avatar.dart';

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  // Data services (lazy wiring; replace with Provider if desired)
  final _groupService = GroupService();
  final _contribService = ContributionService();
  final _memberService = MemberService();
  late final ConfettiController _confettiController;

  // Metrics
  double monthlyTarget = 0;
  double monthlyAchieved = 0;
  double totalSavings = 0;
  int activeMembers = 0;
  String? selectedGroupId;

  // Groups cache
  List<Map<String, dynamic>> _groups = [];
  // Members cache (basic fields: name, phone)
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _membersWithStatus = [];

  // Chart state (dynamic); fallback demo data if empty
  List<BarChartGroupData> _barGroups = [];
  Map<String, double> _distribution = const {};

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  Future<void> _bootstrap(String userId) async {
    // TODO: pick actual current admin userId and fetch groups; using placeholder
    try {
      final groups = await _groupService.fetchGroupsManagedByUser(userId);
      setState(() {
        _groups = groups;
      });
      if (groups.isNotEmpty) {
        selectedGroupId = groups.first['id']?.toString();
        await _loadMonthlyProgress();
      }
    } catch (_) {}
    _maybeCelebrate();
  }

  Future<void> _loadMonthlyProgress() async {
    if (selectedGroupId == null) return;
    final now = DateTime.now();
    final mp = await _groupService.getMonthlyProgress(selectedGroupId!, now.year, now.month);
    // Load analytics
    try {
      final bars = await _contribService.monthlyTotals(selectedGroupId!);
      final groups = <BarChartGroupData>[];
      var x = 0;
      for (final r in bars) {
        final v = r['total'];
        final y = v is num ? v.toDouble() : 0.0;
        groups.add(BarChartGroupData(x: x++, barRods: [BarChartRodData(toY: y, color: AppTheme.royalPurple)]));
      }
      final distRows = await _contribService.distributionByMember(selectedGroupId!);
      final dist = <String, double>{};
      for (final r in distRows) {
        dist[(r['name'] ?? 'Member').toString()] = ((r['total'] ?? 0) as num).toDouble();
      }
      final members = await _memberService.fetchMembers(selectedGroupId!);

      // Compute per-member status using backend-derived monthly requirement per member
      final target = (mp['target'] ?? 0).toDouble();
      double requiredPerMember = 0.0;
      try {
        requiredPerMember = await _contribService.memberMonthlyRequirement(selectedGroupId!);
        if (requiredPerMember == 0.0 && members.isNotEmpty) {
          requiredPerMember = target / members.length;
        }
      } catch (_) {
        requiredPerMember = members.isNotEmpty ? (target / members.length) : 0.0;
      }
      final computed = <Map<String, dynamic>>[];
      for (final m in members) {
        final uid = m['user_id']?.toString() ?? '';
        final st = await _memberService.computeStatusForCurrentPeriod(
          selectedGroupId!,
          uid,
          requiredAmount: requiredPerMember,
          now: DateTime.now(),
        );
        final amt = await _contribService.totalForMemberCurrentMonth(selectedGroupId!, uid);
        computed.add({
          'user_id': uid,
          'name': ('${m['first_name'] ?? ''} ${m['last_name'] ?? ''}').trim(),
          'phone': m['phone']?.toString() ?? '',
          'status': st,
          'amount': amt,
        });
      }

      final ts = await _contribService.totalSavedForGroup(selectedGroupId!);

      setState(() {
        monthlyTarget = (mp['target'] ?? 0).toDouble();
        monthlyAchieved = (mp['achieved'] ?? 0).toDouble();
        totalSavings = ts;
        _barGroups = groups;
        _distribution = dist;
        activeMembers = members.length;
        _members = members;
        _membersWithStatus = computed;
      });
    } catch (_) {
      setState(() {
        monthlyTarget = (mp['target'] ?? 0).toDouble();
        monthlyAchieved = (mp['achieved'] ?? 0).toDouble();
      });
    }
  }

  void _maybeCelebrate() {
    final reached = monthlyAchieved >= monthlyTarget && monthlyTarget > 0;
    if (reached) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (monthlyTarget == 0) ? 0.0 : (monthlyAchieved / monthlyTarget).clamp(0.0, 1.0);

    final auth = Provider.of<AuthService>(context, listen: true);

    // Kick off bootstrap once role/user resolved and we have Postgres user id
    if (auth.roleResolved && auth.postgresUserId != null && _groups.isEmpty) {
      // Schedule after build to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap(auth.postgresUserId!));
    }

    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          // Profile avatar moved to leading position
          leading: Builder(
            builder: (context) {
              final userDataService = Provider.of<UserDataService>(context, listen: false);
              final userData = userDataService.user;
              if (userData != null) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ProfileAvatar(
                    profileImageUrl: userData['profile_image_url']?.toString(),
                    firstName: userData['first_name']?.toString() ?? '',
                    lastName: userData['last_name']?.toString() ?? '',
                    radius: 20,
                    onTap: () => context.go('/profile'),
                    showBorder: true,
                  ),
                );
              }
              return const SizedBox();
            },
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await _loadMonthlyProgress();
                _maybeCelebrate();
              },
            ),
            // Sync status chip bound to SyncService
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Builder(
                builder: (context) {
                  final sync = Provider.of<SyncService>(context, listen: false);
                  final queue = Provider.of<QueueStore>(context, listen: false);
                  return StreamBuilder<List<QueueItem>>(
                    stream: queue.stream,
                    initialData: const [],
                    builder: (context, snapshot) {
                      final pending = snapshot.data?.length ?? queue.pendingCount;
                      return ValueListenableBuilder<SyncState>(
                        valueListenable: sync.stateNotifier,
                        builder: (_, s, __) {
                          final status = switch (s) {
                            SyncState.syncing => SyncStatus.syncing,
                            SyncState.error => SyncStatus.error,
                            _ => SyncStatus.idle,
                          };
                          return Row(
                            children: [
                              _SyncStatusChip(
                                status: status,
                                pendingCount: pending,
                                onSyncNow: () async {
                                  await sync.flush();
                                },
                              ),
                              IconButton(
                                tooltip: 'manager.sync_now'.tr(),
                                icon: const Icon(Icons.sync),
                                onPressed: () async {
                                  await sync.flush();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome header
                  Builder(builder: (context) {
                    String firstName = '';
                    try {
                      firstName = Provider.of<AuthService>(context, listen: false).currentUser?.displayName ?? '';
                    } catch (_) {}
                    try {
                      if (firstName.isEmpty) {
                        firstName = Provider.of<UserDataService>(context, listen: false).firstName;
                      }
                    } catch (_) {}
                    final greeting = firstName.isNotEmpty ? 'Welcome, $firstName!' : 'Welcome!';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(greeting, style: theme.textTheme.headlineSmall),
                    );
                  }),
                  // Dashboard Overview
                  Text('manager.overview'.tr(), style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (_groups.isNotEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedGroupId,
                            items: _groups
                                .map((g) => DropdownMenuItem<String>(
                                      value: g['id']?.toString(),
                                      child: Text(g['name']?.toString() ?? 'Group'),
                                    ))
                                .toList(),
                            onChanged: (val) async {
                              setState(() => selectedGroupId = val);
                              await _loadMonthlyProgress();
                            },
                            decoration: const InputDecoration(
                              labelText: 'Group',
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _KpiCard(label: 'home.total_savings'.tr(), value: 'GHS ${totalSavings.toStringAsFixed(0)}', icon: Icons.savings)),
                      const SizedBox(width: 12),
                      Expanded(child: _KpiCard(label: 'manager.active_members'.tr(), value: '$activeMembers', icon: Icons.group)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('manager.monthly_goal'.tr(), style: theme.textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: [
                            _StatusChip(label: 'Paid', color: Colors.green, count: _membersWithStatus.where((m) => m['status'].toString().contains('paid')).length),
                            _StatusChip(label: 'Pending', color: Colors.amber, count: _membersWithStatus.where((m) => m['status'].toString().contains('pending')).length),
                            _StatusChip(label: 'Overdue', color: theme.colorScheme.error, count: _membersWithStatus.where((m) => m['status'].toString().contains('overdue')).length),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('GHS ${monthlyAchieved.toStringAsFixed(0)} / ${monthlyTarget.toStringAsFixed(0)}',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            Text('${(progress * 100).toStringAsFixed(0)}%',
                                style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: progress,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            valueColor: const AlwaysStoppedAnimation(AppTheme.royalPurple),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
const Icon(IconMapping.award, color: AppTheme.gold, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                progress >= 1.0 ? 'manager.goal_reached'.tr() : 'manager.keep_going'.tr(),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Contribution Tracker (dynamic list placeholder until full wiring)
                  Text('manager.contribution_tracker'.tr(), style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        if (_members.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text('No members in this group yet.', style: theme.textTheme.bodyMedium),
                          )
                        else
                          ..._membersWithStatus.take(10).map((m) {
                            final fullName = (m['name'] as String?) ?? 'Member';
                            final st = m['status'] as MemberPayStatus? ?? MemberPayStatus.pending;
                            final phone = (m['phone'] as String?) ?? '';
                            final amt = (m['amount'] as num?)?.toDouble() ?? 0.0;
                            final uid = (m['user_id'] as String?) ?? '';
                            return _MemberRow(
                              name: fullName,
                              status: st,
                              amount: amt,
                              phone: phone,
                              userId: uid,
                              onReminder: _sendReminder,
                            );
                          }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Analytics (bar + pie)
                  Text('analytics.title'.tr(), style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          barGroups: _barGroups.isNotEmpty
                              ? _barGroups
                              : List.generate(6, (i) {
                                  final y = 3000 + math.Random(i).nextInt(3000);
                                  return BarChartGroupData(x: i, barRods: [BarChartRodData(toY: y.toDouble(), color: AppTheme.royalPurple)]);
                                }),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 28,
                          sections: (_distribution.isNotEmpty ? _distribution : const {
                            'Member A': 20,
                            'Member B': 15,
                            'Member C': 10,
                            'Others': 55,
                          })
                              .entries
                              .map((e) {
                            return PieChartSectionData(
                              value: (e.value).toDouble(),
                              title: e.key,
                              color: _colorForLabel(e.key),
                              radius: 60,
                              titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Smart Contract Controls (mock)
                  Text('manager.smart_contracts'.tr(), style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('manager.automation_desc'.tr())),
                        const SizedBox(width: 12),
FilledButton.icon(
                          onPressed: () async {
                            if (selectedGroupId == null) return;
                            await showSmartContractToggleDialog(context, groupId: selectedGroupId!);
                          },
                          icon: const Icon(IconMapping.lockOpen),
                          label: Text('manager.enable_automation'.tr()),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Member management (stubs)
                  Text('manager.member_management'.tr(), style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.person_add),
                        label: Text('groups.add_member'.tr()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit),
                        label: Text('groups.change_role'.tr()),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 20,
              minBlastForce: 10,
              colors: const [AppTheme.gold, Colors.white, AppTheme.royalPurple],
            ),
          ),
        ],
      ),
      floatingActionButton: const _ManagerExpandableFab(),
    );
  }


  void _sendReminder(String member, MemberPayStatus status, {String? phone, String? userId}) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final channel = status == MemberPayStatus.overdue ? 'SMS' : 'Push';

    if (channel == 'SMS' && (phone != null && phone.isNotEmpty)) {
      // ignore: unawaited_futures
      SmsService().sendReminderSms(
        phoneNumber: phone,
        message: 'Please remember to make your monthly contribution. Thank you.',
      );
    } else {
      // Schedule push reminder via sync queue
      final sync = Provider.of<SyncService>(context, listen: false);
      sync.enqueue(QueueItem(type: 'send_reminder', payload: {
        'groupId': selectedGroupId,
        'userId': userId,
        'memberName': member,
        'when': DateTime.now().toIso8601String(),
      }));
    }

    // Audit log
    // ignore: unawaited_futures
    AuditLogService().logAction(
      userId: auth.postgresUserId ?? 'unknown',
      action: 'send_reminder',
      targetType: 'member',
      targetId: userId,
      metadata: {'channel': channel, 'member': member, 'groupId': selectedGroupId},
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('manager.reminder_sent_via'.tr(args: [channel, member]))),
    );
  }

  Color _colorForLabel(String label) {
    final palette = [
      AppTheme.royalPurple,
      AppTheme.lightPurple,
      AppTheme.gold,
      Colors.orange,
      Colors.teal,
      Colors.pinkAccent,
    ];
    final index = label.hashCode.abs() % palette.length;
    return palette[index];
  }
}

/// Manager-specific expandable FAB with settings and additional options
class _ManagerExpandableFab extends StatefulWidget {
  const _ManagerExpandableFab();

  @override
  State<_ManagerExpandableFab> createState() => _ManagerExpandableFabState();
}

class _ManagerExpandableFabState extends State<_ManagerExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: _isOpen ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Settings button (appears when expanded)
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _expandAnimation.value,
              child: Opacity(
                opacity: _expandAnimation.value,
                child: Visibility(
                  visible: _expandAnimation.value > 0,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: FloatingActionButton.small(
                      heroTag: "settings_fab",
                      onPressed: () {
                        _toggle();
                        context.go('/settings');
                      },
                      tooltip: 'Settings',
                      child: const Icon(IconMapping.settings),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        
        // Analytics button (appears when expanded)
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _expandAnimation.value,
              child: Opacity(
                opacity: _expandAnimation.value,
                child: Visibility(
                  visible: _expandAnimation.value > 0,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: FloatingActionButton.small(
                      heroTag: "analytics_fab",
                      onPressed: () {
                        _toggle();
                        context.go('/analytics');
                      },
                      tooltip: 'Analytics',
                      child: const Icon(IconMapping.barChart),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        
        // Main FAB
        FloatingActionButton(
          heroTag: "main_fab",
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0, // 45 degree rotation when expanded
            duration: const Duration(milliseconds: 250),
            child: Icon(_isOpen ? Icons.close : Icons.add),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _KpiCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.royalPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: AppTheme.royalPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

enum MemberPayStatus { paid, pending, overdue }

// Lightweight helper to avoid importing LocalAuthentication directly in UI widget
class BiometricGate {
  static Future<bool> guard(String reason) async {
    try {
      // Deferred import to avoid heavy deps at file top; simple inline
      // ignore: avoid_print
      final svc = _biometricServiceInstance;
      if (await svc.canCheck()) {
        return await svc.authenticate(reason: reason);
      }
      return true; // if device not supported, proceed
    } catch (_) {
      return false;
    }
  }
}

// Provide a singleton instance
final _biometricServiceInstance = BiometricService();

class _MemberRow extends StatefulWidget {
  final String name;
  final MemberPayStatus status;
  final double amount;
  final String? phone;
  final String? userId;
  final void Function(String, MemberPayStatus, {String? phone, String? userId}) onReminder;
  const _MemberRow({required this.name, required this.status, required this.amount, this.phone, this.userId, required this.onReminder});

  @override
  State<_MemberRow> createState() => _MemberRowState();
}

class _MemberRowState extends State<_MemberRow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    if (widget.status == MemberPayStatus.overdue) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (widget.status) {
      MemberPayStatus.paid => AppTheme.success,
      MemberPayStatus.pending => Colors.amber,
      MemberPayStatus.overdue => theme.colorScheme.error,
    };

    final chip = Chip(
      label: Text(widget.status.name.toUpperCase()),
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
      shape: StadiumBorder(side: BorderSide(color: color.withValues(alpha: 0.4))),
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
leading: CircleAvatar(backgroundColor: AppTheme.royalPurple.withValues(alpha: 0.1), child: const Icon(IconMapping.person, color: AppTheme.royalPurple)),
      title: Text(widget.name, style: theme.textTheme.titleMedium),
      subtitle: Text('GHS ${widget.amount.toStringAsFixed(0)}'),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (widget.status == MemberPayStatus.overdue)
          ScaleTransition(scale: Tween(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)), child: chip)
        else
          chip,
        const SizedBox(width: 8),
IconButton(
          tooltip: 'manager.send_reminder'.tr(),
          icon: const Icon(IconMapping.notifications),
          onPressed: () async {
            // Biometric gate before sending reminder depending on user setting
            final prefs = Provider.of<SecurityPrefsService>(context, listen: false);
            if (prefs.requireBiometric) {
              final ok = await BiometricGate.guard('Authenticate to send reminder');
              if (!ok) return;
            }
            widget.onReminder(widget.name, widget.status, phone: widget.phone, userId: widget.userId);
          },
        ),
      ]),
    );
  }
}

class _SpeedDial extends StatefulWidget {
  final VoidCallback onAddContribution;
  final VoidCallback onAddMember;
  const _SpeedDial({required this.onAddContribution, required this.onAddMember});

  @override
  State<_SpeedDial> createState() => _SpeedDialState();
}

class _SpeedDialState extends State<_SpeedDial> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          if (_open) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 64.0),
              child: FloatingActionButton.small(
                heroTag: 'fab1',
                backgroundColor: theme.colorScheme.secondary,
                onPressed: widget.onAddContribution,
                child: const Icon(Icons.addchart),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 64.0),
              child: FloatingActionButton.small(
                heroTag: 'fab2',
                backgroundColor: theme.colorScheme.secondary,
                onPressed: widget.onAddMember,
                child: const Icon(Icons.person_add),
              ),
            ),
          ],
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _open = !_open;
                if (_open) {
                  _controller.forward();
                } else {
                  _controller.reverse();
                }
              });
            },
            child: AnimatedIcon(icon: AnimatedIcons.menu_close, progress: _controller),
          ),
        ],
      ),
    );
  }
}

enum SyncStatus { idle, syncing, error }

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final int count;
  const _StatusChip({required this.label, required this.color, required this.count});
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label ($count)', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      backgroundColor: color.withValues(alpha: 0.08),
      shape: StadiumBorder(side: BorderSide(color: color.withValues(alpha: 0.3))),
    );
  }
}

class _SyncStatusChip extends StatelessWidget {
  final SyncStatus status;
  final int pendingCount;
  final Future<void> Function()? onSyncNow;
  const _SyncStatusChip({required this.status, this.pendingCount = 0, this.onSyncNow});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (status) {
      SyncStatus.idle => (Icons.cloud_done, 'manager.sync_idle'.tr(), Colors.green),
      SyncStatus.syncing => (Icons.cloud_sync, 'manager.syncing'.tr(), AppTheme.royalPurple),
      SyncStatus.error => (Icons.cloud_off, 'manager.sync_error'.tr(), Theme.of(context).colorScheme.error),
    };

    final avatar = status == SyncStatus.syncing
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: color,
            ),
          )
        : Icon(icon, color: color, size: 18);

    final chip = Chip(
      avatar: avatar,
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      backgroundColor: color.withValues(alpha: 0.08),
      shape: StadiumBorder(side: BorderSide(color: color.withValues(alpha: 0.3))),
    );

    return Tooltip(
      message: pendingCount > 0 ? '$label • ${'manager.pending'.tr()}: $pendingCount' : label,
      child: InkWell(
        onTap: onSyncNow == null ? null : () async { await onSyncNow!(); },
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            chip,
            if (pendingCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    pendingCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
