import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savessa/core/constants/icon_mapping.dart';
import 'package:savessa/services/auth/auth_service.dart';
import 'package:savessa/services/groups/group_service.dart';
import 'package:savessa/shared/widgets/app_card.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _groups = const [];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        title: const Text('Groups'),
        actions: [
          IconButton(
            tooltip: 'Join group',
            icon: const Icon(IconMapping.groupAdd),
            onPressed: () => Navigator.of(context).pushNamed('/groups/join'),
          ),
          IconButton(
            tooltip: 'Create group',
            icon: const Icon(IconMapping.addBox),
            onPressed: () => Navigator.of(context).pushNamed('/groups/create'),
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
                        Navigator.of(context).pushNamed('/groups/${g['id']}');
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: _groups.length,
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _load,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
      ),
    );
  }
}

