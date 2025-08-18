import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savessa/shared/widgets/app_card.dart';
import 'package:savessa/services/auth/auth_service.dart';
import 'package:savessa/services/groups/active_group_service.dart';
import 'package:savessa/services/groups/contribution_service.dart';

class MyContributionsScreen extends StatefulWidget {
  const MyContributionsScreen({super.key});

  @override
  State<MyContributionsScreen> createState() => _MyContributionsScreenState();
}

class _MyContributionsScreenState extends State<MyContributionsScreen> {
  bool _loading = true;
  String? _groupId;
  String? _userId;
  double _thisMonth = 0;
  double _required = 0;
  int _limit = 20;
  List<Map<String, dynamic>> _rows = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final active = Provider.of<ActiveGroupService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);
      if (!active.loading && active.groupId == null) {
        await active.bootstrap(auth);
      }
      _groupId = active.groupId;
      _userId = auth.postgresUserId;
      if (_groupId != null && _userId != null) {
        final svc = ContributionService();
        _thisMonth = await svc.totalForMemberCurrentMonth(_groupId!, _userId!);
        _required = await svc.memberMonthlyRequirement(_groupId!);
        _rows = await svc.recentContributionsForMember(_groupId!, _userId!, limit: _limit);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
appBar: AppBar(
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        title: const Text('My Contributions'),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('This month', style: theme.textTheme.bodySmall),
                              Text('GHS ${_thisMonth.toStringAsFixed(2)}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Required', style: theme.textTheme.bodySmall),
                              Text('GHS ${_required.toStringAsFixed(2)}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: () {
                                  final remaining = (_required - _thisMonth);
                                  final suggested = remaining > 0 ? remaining : 0;
                                  Navigator.of(context).pushNamed(
                                    '/savings/add',
                                    arguments: {'amount': suggested.toStringAsFixed(2)},
                                  );
                                },
                                child: const Text('Contribute remaining'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('History', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _rows.isEmpty
                        ? const AppCard(
                            padding: EdgeInsets.all(16),
                            child: Center(child: Text('No contributions yet.')),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: ListView.separated(
                                  itemCount: _rows.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final r = _rows[index];
                                    final dateStr = (r['date'] ?? '').toString();
                                    final dt = DateTime.tryParse(dateStr)?.toLocal();
                                    final amount = (r['amount'] ?? 0).toString();
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                        child: Icon(Icons.savings, color: theme.colorScheme.primary),
                                      ),
                                      title: Text('GHS $amount', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(dt?.toString() ?? dateStr),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: () async {
                                  setState(() => _limit += 20);
                                  await _load();
                                },
                                child: const Text('Load more'),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
