import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:savessa/core/constants/icon_mapping.dart';
import 'package:savessa/shared/widgets/app_card.dart';
import 'package:savessa/services/auth/auth_service.dart';
import 'package:savessa/services/groups/contribution_service.dart';
import 'package:savessa/services/groups/active_group_service.dart';
import 'package:savessa/shared/widgets/profile_app_bar.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _HistoryList extends StatelessWidget {
  final String? groupId;
  const _HistoryList({required this.groupId});

  @override
  Widget build(BuildContext context) {
    if (groupId == null) {
      return const AppCard(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('Select a group to view history.')),
      );
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ContributionService().recentContributions(groupId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
        }
        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return const AppCard(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('No recent contributions.')),
          );
        }
        return AppCard(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: data.map((row) {
              final name = ('${row['first_name'] ?? ''} ${row['last_name'] ?? ''}').trim();
              final amount = (row['amount'] ?? 0).toString();
              final dateStr = (row['date'] ?? '').toString();
              return ListTile(
                leading: const Icon(IconMapping.arrowUpward, color: Colors.green),
                title: Text(name.isEmpty ? 'Member' : name),
                subtitle: Text(DateTime.tryParse(dateStr)?.toLocal().toString() ?? dateStr),
                trailing: Text('GHS $amount', style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _SavingsScreenState extends State<SavingsScreen> {
  bool _loading = true;
  double _thisMonth = 0;
  double _allTime = 0;
  String? _groupId; // selected/active group id

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // fetch active group
      final active = Provider.of<ActiveGroupService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);
      if (!active.loading && active.groupId == null) {
        await active.bootstrap(auth);
      }
      _groupId = active.groupId;
      if (_groupId != null) {
        final contrib = ContributionService();
        final uid = auth.postgresUserId ?? '';
        _thisMonth = await contrib.totalForMemberCurrentMonth(_groupId!, uid);
        _allTime = await contrib.totalSavedForGroup(_groupId!); // group aggregate for now
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: ProfileAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/savings/add'),
        icon: const Icon(IconMapping.addCircle),
        label: const Text('Add'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(IconMapping.savings, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('This month', style: theme.textTheme.bodySmall),
                              Text('GHS ${_thisMonth.toStringAsFixed(2)}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(IconMapping.savings, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('All time (group)', style: theme.textTheme.bodySmall),
                              Text('GHS ${_allTime.toStringAsFixed(2)}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('History', style: theme.textTheme.titleLarge),
                      TextButton(
                        onPressed: () {
                          context.go('/savings/my');
                        },
                        child: const Text('My contributions'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _HistoryList(groupId: _groupId),
                ],
              ),
            ),
    );
  }
}
