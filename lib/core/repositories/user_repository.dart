import '../models/models.dart';

/// Abstract repository interface for User operations
abstract class UserRepository {
  /// Get user by ID
  Future<UserModel?> getUserById(String userId);

  /// Get user by email
  Future<UserModel?> getUserByEmail(String email);

  /// Get user by phone
  Future<UserModel?> getUserByPhone(String phone);

  /// Get user by email or phone
  Future<UserModel?> getUserByEmailOrPhone(String identifier);

  /// Get user by Firebase UID
  Future<UserModel?> getUserByFirebaseUid(String firebaseUid);

  /// Create new user
  Future<UserModel> createUser({
    required String firstName,
    required String lastName,
    String? otherNames,
    required String email,
    String? phone,
    String role = 'member',
    required String password,
  });

  /// Update user profile
  Future<UserModel> updateUserProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? otherNames,
    String? phone,
    String? email,
    String? profileImageUrl,
  });

  /// Verify user credentials
  Future<UserModel?> verifyCredentials({
    required String identifier,
    required String password,
  });

  /// Mirror Firebase user to database
  Future<void> upsertUserMirror({
    required String firebaseUid,
    String? email,
    String? phone,
    String defaultRole = 'member',
  });

  /// Get user security settings
  Future<UserSecurityModel?> getUserSecurity(String userId);

  /// Update user security settings
  Future<UserSecurityModel> updateUserSecurity({
    required String userId,
    String? totpSecret,
    bool? totpEnabled,
    bool? smsEnabled,
    bool? emailEnabled,
  });

  /// Get user's trusted devices
  Future<List<DeviceTrustModel>> getUserDevices(String userId);

  /// Add or update device trust
  Future<DeviceTrustModel> upsertDeviceTrust({
    required String userId,
    String? deviceId,
    String? fcmToken,
    String? platform,
    bool trusted = true,
  });

  /// Remove device trust
  Future<void> removeDeviceTrust(String deviceId);
}

/// Implementation of UserRepository using DatabaseService
class DatabaseUserRepository implements UserRepository {
  final dynamic _databaseService; // Keep as dynamic for now to avoid circular imports

  DatabaseUserRepository(this._databaseService);

  @override
  Future<UserModel?> getUserById(String userId) async {
    final data = await _databaseService.getUserById(userId);
    return data != null ? UserModel.fromMap(data) : null;
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    final data = await _databaseService.getUserByEmail(email);
    return data != null ? UserModel.fromMap(data) : null;
  }

  @override
  Future<UserModel?> getUserByPhone(String phone) async {
    final data = await _databaseService.getUserByPhone(phone);
    return data != null ? UserModel.fromMap(data) : null;
  }

  @override
  Future<UserModel?> getUserByEmailOrPhone(String identifier) async {
    final data = await _databaseService.getUserByEmailOrPhone(identifier);
    return data != null ? UserModel.fromMap(data) : null;
  }

  @override
  Future<UserModel?> getUserByFirebaseUid(String firebaseUid) async {
    final data = await _databaseService.getUserByFirebaseUid(firebaseUid);
    return data != null ? UserModel.fromMap(data) : null;
  }

  @override
  Future<UserModel> createUser({
    required String firstName,
    required String lastName,
    String? otherNames,
    required String email,
    String? phone,
    String role = 'member',
    required String password,
  }) async {
    final userData = {
      'first_name': firstName,
      'last_name': lastName,
      'other_names': otherNames,
      'email': email,
      'phone': phone ?? '',
      'role': role,
      'password': password,
    };

    await _databaseService.createUser(userData);
    
    // Fetch the created user
    final createdUser = await getUserByEmail(email);
    if (createdUser == null) {
      throw Exception('Failed to create user');
    }
    
    return createdUser;
  }

  @override
  Future<UserModel> updateUserProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? otherNames,
    String? phone,
    String? email,
    String? profileImageUrl,
  }) async {
    await _databaseService.updateUserProfile(
      userId: userId,
      firstName: firstName,
      lastName: lastName,
      otherNames: otherNames,
      phone: phone,
      email: email,
      profileImageUrl: profileImageUrl,
    );

    // Fetch the updated user
    final updatedUser = await getUserById(userId);
    if (updatedUser == null) {
      throw Exception('Failed to update user profile');
    }
    
    return updatedUser;
  }

  @override
  Future<UserModel?> verifyCredentials({
    required String identifier,
    required String password,
  }) async {
    final data = await _databaseService.verifyCredentials(
      identifier: identifier,
      password: password,
    );
    return data != null ? UserModel.fromMap(data) : null;
  }

  @override
  Future<void> upsertUserMirror({
    required String firebaseUid,
    String? email,
    String? phone,
    String defaultRole = 'member',
  }) async {
    await _databaseService.upsertUserMirror(
      firebaseUid: firebaseUid,
      email: email,
      phone: phone,
      defaultRole: defaultRole,
    );
  }

  @override
  Future<UserSecurityModel?> getUserSecurity(String userId) async {
    // This would need to be implemented in DatabaseService
    try {
      final data = await _databaseService.query(
        'SELECT * FROM user_security WHERE user_id = @uid LIMIT 1',
        {'uid': userId},
      );
      return data.isNotEmpty ? UserSecurityModel.fromMap(data.first) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserSecurityModel> updateUserSecurity({
    required String userId,
    String? totpSecret,
    bool? totpEnabled,
    bool? smsEnabled,
    bool? emailEnabled,
  }) async {
    final fields = <String, String>{};
    final params = <String, dynamic>{'uid': userId};
    
    if (totpSecret != null) {
      fields['totp_secret'] = '@totp_secret';
      params['totp_secret'] = totpSecret;
    }
    if (totpEnabled != null) {
      fields['totp_enabled'] = '@totp_enabled';
      params['totp_enabled'] = totpEnabled;
    }
    if (smsEnabled != null) {
      fields['sms_enabled'] = '@sms_enabled';
      params['sms_enabled'] = smsEnabled;
    }
    if (emailEnabled != null) {
      fields['email_enabled'] = '@email_enabled';
      params['email_enabled'] = emailEnabled;
    }
    
    if (fields.isEmpty) {
      // Nothing to update, just return current state
      final current = await getUserSecurity(userId);
      if (current != null) return current;
      
      // Create default security settings
      await _databaseService.execute(
        'INSERT INTO user_security (user_id) VALUES (@uid) ON CONFLICT (user_id) DO NOTHING',
        {'uid': userId},
      );
      return UserSecurityModel(
        userId: userId,
        totpEnabled: false,
        smsEnabled: false,
        emailEnabled: false,
        updatedAt: DateTime.now(),
      );
    }
    
    final setClause = fields.entries.map((e) => '${e.key} = ${e.value}').join(', ');
    final sql = '''
      INSERT INTO user_security (user_id, ${fields.keys.join(', ')}, updated_at)
      VALUES (@uid, ${fields.values.join(', ')}, NOW())
      ON CONFLICT (user_id) DO UPDATE SET $setClause, updated_at = NOW()
    ''';
    
    await _databaseService.execute(sql, params);
    
    // Return updated security settings
    final updated = await getUserSecurity(userId);
    if (updated == null) {
      throw Exception('Failed to update user security settings');
    }
    
    return updated;
  }

  @override
  Future<List<DeviceTrustModel>> getUserDevices(String userId) async {
    try {
      final data = await _databaseService.query(
        'SELECT * FROM device_trust WHERE user_id = @uid ORDER BY last_seen DESC',
        {'uid': userId},
      );
      return data.map((item) => DeviceTrustModel.fromMap(item)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<DeviceTrustModel> upsertDeviceTrust({
    required String userId,
    String? deviceId,
    String? fcmToken,
    String? platform,
    bool trusted = true,
  }) async {
    await _databaseService.execute(
      '''
      INSERT INTO device_trust (user_id, device_id, fcm_token, platform, last_seen, trusted)
      VALUES (@uid, @device_id, @fcm_token, @platform, NOW(), @trusted)
      ON CONFLICT (device_id) DO UPDATE SET 
        fcm_token = COALESCE(EXCLUDED.fcm_token, device_trust.fcm_token),
        platform = COALESCE(EXCLUDED.platform, device_trust.platform),
        last_seen = NOW(),
        trusted = EXCLUDED.trusted
      ''',
      {
        'uid': userId,
        'device_id': deviceId,
        'fcm_token': fcmToken,
        'platform': platform,
        'trusted': trusted,
      },
    );
    
    // Fetch the created/updated device
    final devices = await getUserDevices(userId);
    final device = devices.firstWhere(
      (d) => d.deviceId == deviceId,
      orElse: () => devices.first,
    );
    
    return device;
  }

  @override
  Future<void> removeDeviceTrust(String deviceId) async {
    await _databaseService.execute(
      'DELETE FROM device_trust WHERE device_id = @device_id',
      {'device_id': deviceId},
    );
  }
}
