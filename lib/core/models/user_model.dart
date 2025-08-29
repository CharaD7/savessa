import 'package:equatable/equatable.dart';

/// User data model that matches the database schema
class UserModel extends Equatable {
  final String id;
  final String? firebaseUid;
  final String firstName;
  final String lastName;
  final String? otherNames;
  final String email;
  final String? phone;
  final String role;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    this.firebaseUid,
    required this.firstName,
    required this.lastName,
    this.otherNames,
    required this.email,
    this.phone,
    required this.role,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create UserModel from database Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString() ?? '',
      firebaseUid: map['firebase_uid']?.toString(),
      firstName: map['first_name']?.toString() ?? '',
      lastName: map['last_name']?.toString() ?? '',
      otherNames: map['other_names']?.toString(),
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString(),
      role: map['role']?.toString() ?? 'member',
      profileImageUrl: map['profile_image_url']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Convert UserModel to database Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'first_name': firstName,
      'last_name': lastName,
      'other_names': otherNames,
      'email': email,
      'phone': phone,
      'role': role,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get full display name
  String get fullName {
    final parts = [firstName, otherNames, lastName].where((s) => s?.isNotEmpty == true);
    return parts.join(' ');
  }

  /// Get display name (first + last only)
  String get displayName {
    return '$firstName $lastName'.trim();
  }

  /// Check if user is admin or super_admin
  bool get isAdmin => role == 'admin' || role == 'super_admin';

  /// Check if user has profile image
  bool get hasProfileImage => profileImageUrl?.isNotEmpty == true;

  /// Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? firebaseUid,
    String? firstName,
    String? lastName,
    String? otherNames,
    String? email,
    String? phone,
    String? role,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      otherNames: otherNames ?? this.otherNames,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        firebaseUid,
        firstName,
        lastName,
        otherNames,
        email,
        phone,
        role,
        profileImageUrl,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() => 'UserModel(id: $id, name: $displayName, email: $email, role: $role)';
}

/// User security settings model
class UserSecurityModel extends Equatable {
  final String userId;
  final String? totpSecret;
  final bool totpEnabled;
  final bool smsEnabled;
  final bool emailEnabled;
  final DateTime updatedAt;

  const UserSecurityModel({
    required this.userId,
    this.totpSecret,
    required this.totpEnabled,
    required this.smsEnabled,
    required this.emailEnabled,
    required this.updatedAt,
  });

  factory UserSecurityModel.fromMap(Map<String, dynamic> map) {
    return UserSecurityModel(
      userId: map['user_id']?.toString() ?? '',
      totpSecret: map['totp_secret']?.toString(),
      totpEnabled: map['totp_enabled'] == true,
      smsEnabled: map['sms_enabled'] == true,
      emailEnabled: map['email_enabled'] == true,
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'totp_secret': totpSecret,
      'totp_enabled': totpEnabled,
      'sms_enabled': smsEnabled,
      'email_enabled': emailEnabled,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if any 2FA method is enabled
  bool get hasTwoFactorEnabled => totpEnabled || smsEnabled || emailEnabled;

  UserSecurityModel copyWith({
    String? userId,
    String? totpSecret,
    bool? totpEnabled,
    bool? smsEnabled,
    bool? emailEnabled,
    DateTime? updatedAt,
  }) {
    return UserSecurityModel(
      userId: userId ?? this.userId,
      totpSecret: totpSecret ?? this.totpSecret,
      totpEnabled: totpEnabled ?? this.totpEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [userId, totpSecret, totpEnabled, smsEnabled, emailEnabled, updatedAt];
}

/// Device trust model for security tracking
class DeviceTrustModel extends Equatable {
  final String id;
  final String userId;
  final String? deviceId;
  final String? fcmToken;
  final String? platform;
  final DateTime? lastSeen;
  final bool trusted;

  const DeviceTrustModel({
    required this.id,
    required this.userId,
    this.deviceId,
    this.fcmToken,
    this.platform,
    this.lastSeen,
    required this.trusted,
  });

  factory DeviceTrustModel.fromMap(Map<String, dynamic> map) {
    return DeviceTrustModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      deviceId: map['device_id']?.toString(),
      fcmToken: map['fcm_token']?.toString(),
      platform: map['platform']?.toString(),
      lastSeen: DateTime.tryParse(map['last_seen']?.toString() ?? ''),
      trusted: map['trusted'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'fcm_token': fcmToken,
      'platform': platform,
      'last_seen': lastSeen?.toIso8601String(),
      'trusted': trusted,
    };
  }

  DeviceTrustModel copyWith({
    String? id,
    String? userId,
    String? deviceId,
    String? fcmToken,
    String? platform,
    DateTime? lastSeen,
    bool? trusted,
  }) {
    return DeviceTrustModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      fcmToken: fcmToken ?? this.fcmToken,
      platform: platform ?? this.platform,
      lastSeen: lastSeen ?? this.lastSeen,
      trusted: trusted ?? this.trusted,
    );
  }

  @override
  List<Object?> get props => [id, userId, deviceId, fcmToken, platform, lastSeen, trusted];
}
