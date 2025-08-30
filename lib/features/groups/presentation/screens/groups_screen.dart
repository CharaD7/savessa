import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savessa/shared/widgets/screen_scaffold.dart';
import 'package:savessa/core/roles/role.dart';
import 'package:savessa/core/roles/role_gate.dart';
import 'package:go_router/go_router.dart';
import 'package:savessa/core/constants/icon_mapping.dart';
import 'package:savessa/services/auth/auth_service.dart';
import 'package:savessa/services/groups/group_service.dart';
import 'package:savessa/shared/widgets/app_card.dart';
import 'package:savessa/shared/widgets/profile_app_bar.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _groups = const [];
  bool _refreshing = false;
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final uid = auth.postgresUserId;
      if (uid != null) {
        _groups = await GroupService().listGroupsForUser(uid);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  
  Future<void> _refresh() async {
    // Prevent rapid successive refreshes
    if (_refreshing || (_lastRefresh != null && DateTime.now().difference(_lastRefresh!) < const Duration(seconds: 2))) {
      return;
    }
    
    setState(() => _refreshing = true);
    _lastRefresh = DateTime.now();
    
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final uid = auth.postgresUserId;
      if (uid != null) {
        // Clear cache to force fresh data
        GroupService.clearCache(uid);
        _groups = await GroupService().listGroupsForUser(uid);
      }
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ProfileAppBar(
        actions: [
          IconButton(
            tooltip: 'Join group',
            icon: const Icon(IconMapping.groupAdd),
            onPressed: () => context.go('/groups/join'),
          ),
          RoleGate(
            allow: const [Role.admin],
            fallback: const SizedBox.shrink(),
            child: IconButton(
              tooltip: 'Create group',
              icon: const Icon(IconMapping.addBox),
              onPressed: () => context.go('/groups/create'),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_groups.isEmpty)
              ? const AppCard(padding: EdgeInsets.all(16), child: Center(child: Text('You are not in any groups yet.')))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (_, i) {
                    final g = _groups[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(IconMapping.group)),
                      title: Text(g['name']?.toString() ?? 'Group'),
                      subtitle: Text('Code: ${g['invite_code'] ?? '-'}'),
                      trailing: const Icon(IconMapping.chevronRight),
                      onTap: () {
                        // Navigate to details placeholder
                        context.go('/groups/${g['id']}');
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: _groups.length,
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _refreshing ? null : _refresh,
        icon: _refreshing 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.refresh),
        label: Text(_refreshing ? 'Refreshing...' : 'Refresh'),
      ),
    );
  }
}

