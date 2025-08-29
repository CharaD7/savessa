import '../models/models.dart';

/// Abstract repository interface for Contribution operations
abstract class ContributionRepository {
  /// Get contribution by ID
  Future<ContributionModel?> getContributionById(String contributionId);

  /// Get contributions with filters
  Future<List<ContributionModel>> getContributions({
    ContributionFilter? filter,
    bool includeUser = false,
    bool includeGroup = false,
  });

  /// Get recent contributions for a group
  Future<List<ContributionModel>> getRecentContributions({
    required String groupId,
    int limit = 20,
    bool includeUser = true,
  });

  /// Get recent contributions for a member
  Future<List<ContributionModel>> getMemberRecentContributions({
    required String groupId,
    required String userId,
    int limit = 20,
  });

  /// Create new contribution
  Future<ContributionModel> createContribution({
    required String groupId,
    required String userId,
    required double amount,
    DateTime? date,
    String status = 'recorded',
  });

  /// Update contribution
  Future<ContributionModel> updateContribution({
    required String contributionId,
    double? amount,
    DateTime? date,
    String? status,
  });

  /// Delete contribution
  Future<void> deleteContribution(String contributionId);

  /// Get total saved for group
  Future<double> getTotalSavedForGroup(String groupId);

  /// Get total for member in current month
  Future<double> getMemberCurrentMonthTotal({
    required String groupId,
    required String userId,
  });

  /// Get monthly totals for group
  Future<List<Map<String, dynamic>>> getMonthlyTotals({
    required String groupId,
    int monthsBack = 6,
  });

  /// Get distribution by member for group
  Future<List<Map<String, dynamic>>> getDistributionByMember(String groupId);

  /// Get member monthly requirement
  Future<double> getMemberMonthlyRequirement(String groupId);

  /// Get contribution statistics
  Future<ContributionStatsModel> getContributionStats({
    String? groupId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Batch create contributions
  Future<List<ContributionModel>> batchCreateContributions(
    List<Map<String, dynamic>> contributions,
  );
}

/// Implementation of ContributionRepository using DatabaseService
class DatabaseContributionRepository implements ContributionRepository {
  final dynamic _databaseService;

  DatabaseContributionRepository(this._databaseService);

  @override
  Future<ContributionModel?> getContributionById(String contributionId) async {
    try {
      final data = await _databaseService.query(
        '''
        SELECT c.*, u.first_name, u.last_name, u.email, u.profile_image_url,
               g.name as group_name
        FROM contributions c
        LEFT JOIN users u ON u.id = c.user_id
        LEFT JOIN groups g ON g.id = c.group_id
        WHERE c.id = @cid LIMIT 1
        ''',
        {'cid': contributionId},
      );

      if (data.isEmpty) return null;

      final item = data.first;
      UserModel? user;
      GroupModel? group;

      if (item['first_name'] != null) {
        user = UserModel.fromMap(item);
      }
      if (item['group_name'] != null) {
        group = GroupModel.fromMap(item);
      }

      return ContributionModel.fromMap(item, user: user, group: group);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ContributionModel>> getContributions({
    ContributionFilter? filter,
    bool includeUser = false,
    bool includeGroup = false,
  }) async {
    final conditions = <String>[];
    final params = <String, dynamic>{};

    // Build WHERE conditions
    if (filter?.groupId != null) {
      conditions.add('c.group_id = @group_id');
      params['group_id'] = filter!.groupId;
    }
    if (filter?.userId != null) {
      conditions.add('c.user_id = @user_id');
      params['user_id'] = filter!.userId;
    }
    if (filter?.status != null) {
      conditions.add('c.status = @status');
      params['status'] = filter!.status;
    }
    if (filter?.startDate != null) {
      conditions.add('c.date >= @start_date');
      params['start_date'] = filter!.startDate!.toIso8601String().split('T')[0];
    }
    if (filter?.endDate != null) {
      conditions.add('c.date <= @end_date');
      params['end_date'] = filter!.endDate!.toIso8601String().split('T')[0];
    }
    if (filter?.minAmount != null) {
      conditions.add('c.amount >= @min_amount');
      params['min_amount'] = filter!.minAmount;
    }
    if (filter?.maxAmount != null) {
      conditions.add('c.amount <= @max_amount');
      params['max_amount'] = filter!.maxAmount;
    }

    // Build SELECT fields
    String selectFields = 'c.*';
    String joins = '';

    if (includeUser) {
      selectFields += ', u.first_name, u.last_name, u.email, u.profile_image_url';
      joins += ' LEFT JOIN users u ON u.id = c.user_id';
    }
    if (includeGroup) {
      selectFields += ', g.name as group_name, g.description as group_description';
      joins += ' LEFT JOIN groups g ON g.id = c.group_id';
    }

    // Build final query
    String sql = 'SELECT $selectFields FROM contributions c$joins';
    if (conditions.isNotEmpty) {
      sql += ' WHERE ${conditions.join(' AND ')}';
    }
    sql += ' ORDER BY c.date DESC, c.created_at DESC';

    // Add limit and offset
    if (filter != null) {
      params['limit'] = filter.limit;
      params['offset'] = filter.offset;
      sql += ' LIMIT @limit OFFSET @offset';
    }

    try {
      final data = await _databaseService.query(sql, params);
      return data.map((item) {
        UserModel? user;
        GroupModel? group;

        if (includeUser && item['first_name'] != null) {
          user = UserModel.fromMap(item);
        }
        if (includeGroup && item['group_name'] != null) {
          group = GroupModel.fromMap(item);
        }

        return ContributionModel.fromMap(item, user: user, group: group);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<ContributionModel>> getRecentContributions({
    required String groupId,
    int limit = 20,
    bool includeUser = true,
  }) async {
    final data = await _databaseService.recentContributions(groupId, limit: limit);
    return data.map((item) {
      UserModel? user;
      if (includeUser && item['first_name'] != null) {
        user = UserModel.fromMap(item);
      }
      return ContributionModel.fromMap(item, user: user);
    }).toList();
  }

  @override
  Future<List<ContributionModel>> getMemberRecentContributions({
    required String groupId,
    required String userId,
    int limit = 20,
  }) async {
    final data = await _databaseService.recentContributionsForMember(
      groupId,
      userId,
      limit: limit,
    );
    return data.map((item) => ContributionModel.fromMap(item)).toList();
  }

  @override
  Future<ContributionModel> createContribution({
    required String groupId,
    required String userId,
    required double amount,
    DateTime? date,
    String status = 'recorded',
  }) async {
    final success = await _databaseService.addContribution(
      groupId: groupId,
      userId: userId,
      amount: amount,
      date: date,
    );

    if (!success) {
      throw Exception('Failed to create contribution');
    }

    // Find the created contribution
    final contributions = await getRecentContributions(
      groupId: groupId,
      limit: 10,
    );

    final contribution = contributions.firstWhere(
      (c) => c.userId == userId && c.amount == amount,
      orElse: () => throw Exception('Failed to retrieve created contribution'),
    );

    return contribution;
  }

  @override
  Future<ContributionModel> updateContribution({
    required String contributionId,
    double? amount,
    DateTime? date,
    String? status,
  }) async {
    final fields = <String, String>{};
    final params = <String, dynamic>{'cid': contributionId};

    if (amount != null) {
      fields['amount'] = '@amount';
      params['amount'] = amount;
    }
    if (date != null) {
      fields['date'] = '@date';
      params['date'] = date.toIso8601String().split('T')[0];
    }
    if (status != null) {
      fields['status'] = '@status';
      params['status'] = status;
    }

    if (fields.isNotEmpty) {
      final setClause = fields.entries.map((e) => '${e.key} = ${e.value}').join(', ');
      await _databaseService.execute(
        'UPDATE contributions SET $setClause, updated_at = NOW() WHERE id = @cid',
        params,
      );
    }

    final updated = await getContributionById(contributionId);
    if (updated == null) {
      throw Exception('Failed to update contribution');
    }

    return updated;
  }

  @override
  Future<void> deleteContribution(String contributionId) async {
    await _databaseService.execute(
      'DELETE FROM contributions WHERE id = @cid',
      {'cid': contributionId},
    );
  }

  @override
  Future<double> getTotalSavedForGroup(String groupId) async {
    return await _databaseService.totalSavedForGroup(groupId);
  }

  @override
  Future<double> getMemberCurrentMonthTotal({
    required String groupId,
    required String userId,
  }) async {
    return await _databaseService.totalForMemberCurrentMonth(groupId, userId);
  }

  @override
  Future<List<Map<String, dynamic>>> getMonthlyTotals({
    required String groupId,
    int monthsBack = 6,
  }) async {
    return await _databaseService.monthlyTotals(groupId, monthsBack: monthsBack);
  }

  @override
  Future<List<Map<String, dynamic>>> getDistributionByMember(String groupId) async {
    return await _databaseService.distributionByMember(groupId);
  }

  @override
  Future<double> getMemberMonthlyRequirement(String groupId) async {
    return await _databaseService.memberMonthlyRequirement(groupId);
  }

  @override
  Future<ContributionStatsModel> getContributionStats({
    String? groupId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final conditions = <String>[];
      final params = <String, dynamic>{};

      if (groupId != null) {
        conditions.add('group_id = @group_id');
        params['group_id'] = groupId;
      }
      if (userId != null) {
        conditions.add('user_id = @user_id');
        params['user_id'] = userId;
      }
      if (startDate != null) {
        conditions.add('date >= @start_date');
        params['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        conditions.add('date <= @end_date');
        params['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

      // Get basic stats
      final statsData = await _databaseService.query(
        '''
        SELECT 
          COALESCE(SUM(amount), 0) as total_amount,
          COUNT(*) as total_count,
          COALESCE(AVG(amount), 0) as average_amount,
          MIN(date) as first_contribution,
          MAX(date) as last_contribution
        FROM contributions
        $whereClause
        ''',
        params,
      );

      // Get monthly totals
      final monthlyData = await _databaseService.query(
        '''
        SELECT TO_CHAR(date, 'YYYY-MM') as month, SUM(amount) as total
        FROM contributions
        $whereClause
        GROUP BY TO_CHAR(date, 'YYYY-MM')
        ORDER BY month
        ''',
        params,
      );

      // Get member totals (only if group is specified)
      final memberData = groupId != null
          ? await _databaseService.query(
              '''
              SELECT u.first_name || ' ' || u.last_name as member, SUM(c.amount) as total
              FROM contributions c
              JOIN users u ON u.id = c.user_id
              WHERE c.group_id = @group_id
              GROUP BY u.id, u.first_name, u.last_name
              ORDER BY total DESC
              ''',
              {'group_id': groupId},
            )
          : <Map<String, dynamic>>[];

      final stats = statsData.first;
      
      return ContributionStatsModel(
        totalAmount: (stats['total_amount'] as num?)?.toDouble() ?? 0.0,
        totalCount: (stats['total_count'] as num?)?.toInt() ?? 0,
        averageAmount: (stats['average_amount'] as num?)?.toDouble() ?? 0.0,
        firstContribution: DateTime.tryParse(stats['first_contribution']?.toString() ?? ''),
        lastContribution: DateTime.tryParse(stats['last_contribution']?.toString() ?? ''),
        monthlyTotals: Map.fromEntries(
          monthlyData.map((row) => MapEntry(
            row['month']?.toString() ?? '',
            (row['total'] as num?)?.toDouble() ?? 0.0,
          )),
        ),
        memberTotals: Map.fromEntries(
          memberData.map((row) => MapEntry(
            row['member']?.toString() ?? '',
            (row['total'] as num?)?.toDouble() ?? 0.0,
          )),
        ),
      );
    } catch (_) {
      return const ContributionStatsModel(
        totalAmount: 0.0,
        totalCount: 0,
        averageAmount: 0.0,
        monthlyTotals: {},
        memberTotals: {},
      );
    }
  }

  @override
  Future<List<ContributionModel>> batchCreateContributions(
    List<Map<String, dynamic>> contributions,
  ) async {
    final created = <ContributionModel>[];

    // Process in batches to avoid overwhelming the database
    for (final contributionData in contributions) {
      try {
        final contribution = await createContribution(
          groupId: contributionData['group_id']?.toString() ?? '',
          userId: contributionData['user_id']?.toString() ?? '',
          amount: (contributionData['amount'] as num?)?.toDouble() ?? 0.0,
          date: DateTime.tryParse(contributionData['date']?.toString() ?? ''),
          status: contributionData['status']?.toString() ?? 'recorded',
        );
        created.add(contribution);
      } catch (_) {
        // Skip failed contributions and continue
      }
    }

    return created;
  }
}
