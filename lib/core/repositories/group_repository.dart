import '../models/models.dart';

/// Abstract repository interface for Group operations
abstract class GroupRepository {
  /// Get group by ID
  Future<GroupModel?> getGroupById(String groupId);

  /// Get groups managed by user
  Future<List<GroupModel>> getGroupsManagedByUser(String userId);

  /// Get groups where user is a member
  Future<List<GroupModel>> getGroupsForUser(String userId);

  /// Get groups with metadata for user
  Future<List<GroupWithMetadata>> getGroupsWithMetadataForUser(String userId);

  /// Create new group
  Future<GroupModel> createGroup({
    required String name,
    String? description,
    required String createdBy,
    double monthlyGoal = 0.0,
    bool smartContractEnabled = false,
  });

  /// Update group
  Future<GroupModel> updateGroup({
    required String groupId,
    String? name,
    String? description,
    double? monthlyGoal,
    bool? smartContractEnabled,
  });

  /// Delete group
  Future<void> deleteGroup(String groupId);

  /// Join group by invite code
  Future<bool> joinGroupByInviteCode({
    required String userId,
    required String inviteCode,
  });

  /// Get group members
  Future<List<GroupMemberModel>> getGroupMembers(String groupId);

  /// Add member to group
  Future<GroupMemberModel> addGroupMember({
    required String groupId,
    required String userId,
    String role = 'member',
    String status = 'active',
  });

  /// Update member role
  Future<GroupMemberModel> updateMemberRole({
    required String groupId,
    required String userId,
    required String role,
  });

  /// Update member status
  Future<GroupMemberModel> updateMemberStatus({
    required String groupId,
    required String userId,
    required String status,
  });

  /// Remove member from group
  Future<void> removeMember({
    required String groupId,
    required String userId,
  });

  /// Get monthly goals for group
  Future<List<MonthlyGoalModel>> getMonthlyGoals(String groupId);

  /// Get current month goal
  Future<MonthlyGoalModel?> getCurrentMonthGoal(String groupId);

  /// Set monthly goal
  Future<MonthlyGoalModel> setMonthlyGoal({
    required String groupId,
    required int month,
    required int year,
    required double targetAmount,
  });

  /// Update goal progress
  Future<MonthlyGoalModel> updateGoalProgress({
    required String groupId,
    required int month,
    required int year,
    required double achievedAmount,
    DateTime? achievedAt,
  });
}

/// Implementation of GroupRepository using DatabaseService
class DatabaseGroupRepository implements GroupRepository {
  final dynamic _databaseService;

  DatabaseGroupRepository(this._databaseService);

  @override
  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      final data = await _databaseService.query(
        'SELECT * FROM groups WHERE id = @gid LIMIT 1',
        {'gid': groupId},
      );
      return data.isNotEmpty ? GroupModel.fromMap(data.first) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<GroupModel>> getGroupsManagedByUser(String userId) async {
    final data = await _databaseService.fetchGroupsManagedByUser(userId);
    return data.map((item) => GroupModel.fromMap(item)).toList();
  }

  @override
  Future<List<GroupModel>> getGroupsForUser(String userId) async {
    final data = await _databaseService.listGroupsForUser(userId);
    return data.map((item) => GroupModel.fromMap(item)).toList();
  }

  @override
  Future<List<GroupWithMetadata>> getGroupsWithMetadataForUser(String userId) async {
    final groups = await getGroupsForUser(userId);
    final List<GroupWithMetadata> groupsWithMetadata = [];

    for (final group in groups) {
      final members = await getGroupMembers(group.id);
      final currentGoal = await getCurrentMonthGoal(group.id);
      
      // Calculate total saved (this would be implemented in contribution service)
      double totalSaved = 0.0;
      double currentMonthSaved = 0.0;
      
      try {
        final totalData = await _databaseService.query(
          'SELECT COALESCE(SUM(amount),0) AS total FROM contributions WHERE group_id = @gid',
          {'gid': group.id},
        );
        totalSaved = (totalData.first['total'] as num?)?.toDouble() ?? 0.0;

        final currentMonthData = await _databaseService.query(
          '''
          SELECT COALESCE(SUM(amount),0) AS total FROM contributions 
          WHERE group_id = @gid 
            AND date >= date_trunc('month', CURRENT_DATE)
            AND date < (date_trunc('month', CURRENT_DATE) + INTERVAL '1 month')
          ''',
          {'gid': group.id},
        );
        currentMonthSaved = (currentMonthData.first['total'] as num?)?.toDouble() ?? 0.0;
      } catch (_) {
        // Handle error silently, keep defaults
      }

      groupsWithMetadata.add(GroupWithMetadata(
        group: group,
        memberCount: members.length,
        totalSaved: totalSaved,
        currentMonthSaved: currentMonthSaved,
        members: members,
        currentGoal: currentGoal,
      ));
    }

    return groupsWithMetadata;
  }

  @override
  Future<GroupModel> createGroup({
    required String name,
    String? description,
    required String createdBy,
    double monthlyGoal = 0.0,
    bool smartContractEnabled = false,
  }) async {
    final data = await _databaseService.createGroup(
      name: name,
      description: description,
      createdBy: createdBy,
    );
    
    if (data == null) {
      throw Exception('Failed to create group');
    }

    var group = GroupModel.fromMap(data);

    // Update additional fields if needed
    if (monthlyGoal != 0.0 || smartContractEnabled) {
      group = await updateGroup(
        groupId: group.id,
        monthlyGoal: monthlyGoal,
        smartContractEnabled: smartContractEnabled,
      );
    }

    return group;
  }

  @override
  Future<GroupModel> updateGroup({
    required String groupId,
    String? name,
    String? description,
    double? monthlyGoal,
    bool? smartContractEnabled,
  }) async {
    final fields = <String, String>{};
    final params = <String, dynamic>{'gid': groupId};

    if (name != null) {
      fields['name'] = '@name';
      params['name'] = name;
    }
    if (description != null) {
      fields['description'] = '@description';
      params['description'] = description;
    }
    if (monthlyGoal != null) {
      fields['monthly_goal'] = '@monthly_goal';
      params['monthly_goal'] = monthlyGoal;
    }
    if (smartContractEnabled != null) {
      fields['smart_contract_enabled'] = '@smart_contract_enabled';
      params['smart_contract_enabled'] = smartContractEnabled;
    }

    if (fields.isNotEmpty) {
      final setClause = fields.entries.map((e) => '${e.key} = ${e.value}').join(', ');
      await _databaseService.execute(
        'UPDATE groups SET $setClause, updated_at = NOW() WHERE id = @gid',
        params,
      );
    }

    final updated = await getGroupById(groupId);
    if (updated == null) {
      throw Exception('Failed to update group');
    }

    return updated;
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await _databaseService.execute(
      'DELETE FROM groups WHERE id = @gid',
      {'gid': groupId},
    );
  }

  @override
  Future<bool> joinGroupByInviteCode({
    required String userId,
    required String inviteCode,
  }) async {
    return await _databaseService.joinByInviteCode(
      userId: userId,
      inviteCode: inviteCode,
    );
  }

  @override
  Future<List<GroupMemberModel>> getGroupMembers(String groupId) async {
    try {
      final data = await _databaseService.query(
        '''
        SELECT gm.*, u.first_name, u.last_name, u.email, u.profile_image_url
        FROM group_members gm
        LEFT JOIN users u ON u.id = gm.user_id
        WHERE gm.group_id = @gid
        ORDER BY gm.joined_at ASC
        ''',
        {'gid': groupId},
      );

      return data.map((item) {
        UserModel? user;
        if (item['first_name'] != null) {
          user = UserModel.fromMap(item);
        }
        return GroupMemberModel.fromMap(item, user: user);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<GroupMemberModel> addGroupMember({
    required String groupId,
    required String userId,
    String role = 'member',
    String status = 'active',
  }) async {
    await _databaseService.execute(
      '''
      INSERT INTO group_members (group_id, user_id, role, status, joined_at)
      VALUES (@gid, @uid, @role, @status, NOW())
      ON CONFLICT (group_id, user_id) DO UPDATE SET
        role = EXCLUDED.role,
        status = EXCLUDED.status
      ''',
      {
        'gid': groupId,
        'uid': userId,
        'role': role,
        'status': status,
      },
    );

    final members = await getGroupMembers(groupId);
    return members.firstWhere((m) => m.userId == userId);
  }

  @override
  Future<GroupMemberModel> updateMemberRole({
    required String groupId,
    required String userId,
    required String role,
  }) async {
    await _databaseService.execute(
      'UPDATE group_members SET role = @role WHERE group_id = @gid AND user_id = @uid',
      {'gid': groupId, 'uid': userId, 'role': role},
    );

    final members = await getGroupMembers(groupId);
    return members.firstWhere((m) => m.userId == userId);
  }

  @override
  Future<GroupMemberModel> updateMemberStatus({
    required String groupId,
    required String userId,
    required String status,
  }) async {
    await _databaseService.execute(
      'UPDATE group_members SET status = @status WHERE group_id = @gid AND user_id = @uid',
      {'gid': groupId, 'uid': userId, 'status': status},
    );

    final members = await getGroupMembers(groupId);
    return members.firstWhere((m) => m.userId == userId);
  }

  @override
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    await _databaseService.execute(
      'DELETE FROM group_members WHERE group_id = @gid AND user_id = @uid',
      {'gid': groupId, 'uid': userId},
    );
  }

  @override
  Future<List<MonthlyGoalModel>> getMonthlyGoals(String groupId) async {
    try {
      final data = await _databaseService.query(
        'SELECT * FROM monthly_goals WHERE group_id = @gid ORDER BY year DESC, month DESC',
        {'gid': groupId},
      );
      return data.map((item) => MonthlyGoalModel.fromMap(item)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<MonthlyGoalModel?> getCurrentMonthGoal(String groupId) async {
    try {
      final now = DateTime.now();
      final data = await _databaseService.query(
        'SELECT * FROM monthly_goals WHERE group_id = @gid AND year = @year AND month = @month LIMIT 1',
        {'gid': groupId, 'year': now.year, 'month': now.month},
      );
      return data.isNotEmpty ? MonthlyGoalModel.fromMap(data.first) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<MonthlyGoalModel> setMonthlyGoal({
    required String groupId,
    required int month,
    required int year,
    required double targetAmount,
  }) async {
    await _databaseService.execute(
      '''
      INSERT INTO monthly_goals (group_id, month, year, target_amount)
      VALUES (@gid, @month, @year, @target)
      ON CONFLICT (group_id, month, year) DO UPDATE SET
        target_amount = EXCLUDED.target_amount
      ''',
      {
        'gid': groupId,
        'month': month,
        'year': year,
        'target': targetAmount,
      },
    );

    final goals = await getMonthlyGoals(groupId);
    return goals.firstWhere((g) => g.month == month && g.year == year);
  }

  @override
  Future<MonthlyGoalModel> updateGoalProgress({
    required String groupId,
    required int month,
    required int year,
    required double achievedAmount,
    DateTime? achievedAt,
  }) async {
    await _databaseService.execute(
      '''
      UPDATE monthly_goals 
      SET achieved_amount = @achieved, achieved_at = @achieved_at
      WHERE group_id = @gid AND month = @month AND year = @year
      ''',
      {
        'gid': groupId,
        'month': month,
        'year': year,
        'achieved': achievedAmount,
        'achieved_at': achievedAt?.toIso8601String(),
      },
    );

    final goals = await getMonthlyGoals(groupId);
    return goals.firstWhere((g) => g.month == month && g.year == year);
  }
}
