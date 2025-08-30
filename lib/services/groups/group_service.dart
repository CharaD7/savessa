import 'package:savessa/services/database/database_service.dart';

class GroupService {
  final DatabaseService _db = DatabaseService();
  
  // Simple cache to avoid repeated queries
  static final Map<String, List<Map<String, dynamic>>> _groupsCache = {};
  static final Map<String, DateTime> _lastFetchTime = {};
  static const Duration _cacheTimeout = Duration(seconds: 30);

  Future<List<Map<String, dynamic>>> fetchGroupsManagedByUser(String userId) async {
    final cacheKey = 'managed_$userId';
    final now = DateTime.now();
    
    // Check if we have cached data that's still valid
    if (_groupsCache.containsKey(cacheKey) && 
        _lastFetchTime.containsKey(cacheKey) &&
        now.difference(_lastFetchTime[cacheKey]!) < _cacheTimeout) {
      return _groupsCache[cacheKey]!;
    }
    
    try {
      final rows = await _db.query(
        'SELECT * FROM groups WHERE created_by = @uid ORDER BY created_at DESC',
        {'uid': userId},
      );
      
      // Cache the result
      _groupsCache[cacheKey] = rows;
      _lastFetchTime[cacheKey] = now;
      
      return rows;
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> listGroupsForUser(String userId) async {
    final cacheKey = 'user_$userId';
    final now = DateTime.now();
    
    // Check if we have cached data that's still valid
    if (_groupsCache.containsKey(cacheKey) && 
        _lastFetchTime.containsKey(cacheKey) &&
        now.difference(_lastFetchTime[cacheKey]!) < _cacheTimeout) {
      return _groupsCache[cacheKey]!;
    }
    
    try {
      final rows = await _db.query(
        '''
        SELECT g.*
        FROM group_members gm
        JOIN groups g ON g.id = gm.group_id
        WHERE gm.user_id = @uid
        ORDER BY g.created_at DESC
        ''' ,
        {'uid': userId},
      );
      
      // Cache the result
      _groupsCache[cacheKey] = rows;
      _lastFetchTime[cacheKey] = now;
      
      return rows;
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> createGroup({required String name, String? description, required String createdBy}) async {
    try {
      // Generate a simple 6-char alphanumeric code
      final code = _generateCode();
      await _db.execute(
        '''
        INSERT INTO groups (name, description, created_by, invite_code, created_at, updated_at)
        VALUES (@n, @d, @uid, @code, NOW(), NOW())
        ''' ,
        {'n': name, 'd': description ?? '', 'uid': createdBy, 'code': code},
      );
      // Fetch created row (assuming invite_code is unique)
      final rows = await _db.query('SELECT * FROM groups WHERE invite_code = @c LIMIT 1', {'c': code});
      final group = rows.isNotEmpty ? rows.first : null;
      if (group != null) {
        // Add creator as member/admin
        await _db.execute(
          '''
          INSERT INTO group_members (group_id, user_id, role, joined_at)
          VALUES (@gid, @uid, 'admin', NOW())
          ''' ,
          {'gid': group['id'], 'uid': createdBy},
        );
      }
      return group;
    } catch (e) {
      return null;
    }
  }

  Future<bool> joinByInviteCode({required String userId, required String inviteCode}) async {
    try {
      final rows = await _db.query('SELECT id FROM groups WHERE invite_code = @c LIMIT 1', {'c': inviteCode});
      if (rows.isEmpty) return false;
      final gid = rows.first['id'];
      // Avoid duplicate membership
      final existing = await _db.query(
        'SELECT 1 FROM group_members WHERE group_id = @gid AND user_id = @uid LIMIT 1',
        {'gid': gid, 'uid': userId},
      );
      if (existing.isEmpty) {
        await _db.execute(
          '''
          INSERT INTO group_members (group_id, user_id, role, joined_at)
          VALUES (@gid, @uid, 'member', NOW())
          ''' ,
          {'gid': gid, 'uid': userId},
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    // Simple deterministic mix (sufficient for invite codes)
    var x = now;
    final code = List.generate(6, (i) {
      x = (x * 1103515245 + 12345) & 0x7fffffff;
      return chars[x % chars.length];
    }).join();
    return code;
  }

  Future<Map<String, num>> getMonthlyProgress(String groupId, int year, int month) async {
    try {
      final goalRows = await _db.query(
        'SELECT target_amount, achieved_amount FROM monthly_goals WHERE group_id = @gid AND year = @y AND month = @m LIMIT 1',
        {'gid': groupId, 'y': year, 'm': month},
      );
      num target = 0;
      num achieved = 0;
      if (goalRows.isNotEmpty) {
        target = (goalRows.first['target_amount'] ?? 0) as num;
        achieved = (goalRows.first['achieved_amount'] ?? 0) as num;
      } else {
        // compute achieved from contributions if no row
        final contrib = await _db.query(
          'SELECT COALESCE(SUM(amount),0) AS total FROM contributions WHERE group_id = @gid AND EXTRACT(YEAR FROM date) = @y AND EXTRACT(MONTH FROM date) = @m',
          {'gid': groupId, 'y': year, 'm': month},
        );
        achieved = (contrib.first['total'] ?? 0) as num;
      }
      return {'target': target, 'achieved': achieved};
    } catch (_) {
      return {'target': 0, 'achieved': 0};
    }
  }

  Future<bool> setSmartContractEnabled(String groupId, bool enabled) async {
    try {
      await _db.execute(
        'UPDATE groups SET smart_contract_enabled = @e, updated_at = NOW() WHERE id = @gid',
        {'e': enabled, 'gid': groupId},
      );
      return true;
    } catch (_) {
      return false;
    }
  }
  
  // Method to clear cache when groups are modified
  static void clearCache([String? userId]) {
    if (userId != null) {
      _groupsCache.remove('managed_$userId');
      _groupsCache.remove('user_$userId');
      _lastFetchTime.remove('managed_$userId');
      _lastFetchTime.remove('user_$userId');
    } else {
      _groupsCache.clear();
      _lastFetchTime.clear();
    }
  }
}
