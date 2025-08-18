import 'package:flutter/foundation.dart';
import 'package:savessa/services/auth/auth_service.dart';
import 'package:savessa/services/groups/group_service.dart';

class ActiveGroupService with ChangeNotifier {
  final GroupService _groups = GroupService();

  bool _loading = false;
  bool get loading => _loading;

  List<Map<String, dynamic>> _available = const [];
  List<Map<String, dynamic>> get available => _available;

  String? _groupId;
  String? get groupId => _groupId;
  String? _groupName;
  String? get groupName => _groupName;

  Future<void> bootstrap(AuthService auth) async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      final uid = auth.postgresUserId;
      if (uid == null) return;
      final groups = await _groups.fetchGroupsManagedByUser(uid);
      _available = groups;
      if (_groupId == null && groups.isNotEmpty) {
        _groupId = groups.first['id']?.toString();
        _groupName = groups.first['name']?.toString();
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setActive(String id, String name) {
    _groupId = id;
    _groupName = name;
    notifyListeners();
  }
}

