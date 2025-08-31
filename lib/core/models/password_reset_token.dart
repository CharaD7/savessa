import 'package:equatable/equatable.dart';

/// Represents a password reset token for forgot password functionality
class PasswordResetToken extends Equatable {
  /// Unique identifier for the token
  final String id;
  
  /// ID of the user requesting password reset
  final String userId;
  
  /// Hashed token value (stored securely in database)
  final List<int> tokenHash;
  
  /// Type of reset method ('email' or 'sms')
  final String type;
  
  /// Timestamp when the token expires
  final DateTime expiresAt;
  
  /// Whether the token has been used
  final bool used;
  
  /// Timestamp when the token was created
  final DateTime createdAt;

  const PasswordResetToken({
    required this.id,
    required this.userId,
    required this.tokenHash,
    required this.type,
    required this.expiresAt,
    this.used = false,
    required this.createdAt,
  });

  /// Creates a PasswordResetToken from a database row
  factory PasswordResetToken.fromMap(Map<String, dynamic> map) {
    return PasswordResetToken(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      tokenHash: (map['token_hash'] as List<int>?) ?? [],
      type: map['type']?.toString() ?? '',
      expiresAt: map['expires_at'] as DateTime,
      used: (map['used'] as bool?) ?? false,
      createdAt: map['created_at'] as DateTime,
    );
  }

  /// Converts the PasswordResetToken to a map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'token_hash': tokenHash,
      'type': type,
      'expires_at': expiresAt.toIso8601String(),
      'used': used,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Returns true if the token is currently valid (not expired and not used)
  bool get isValid => !used && DateTime.now().isBefore(expiresAt);

  /// Returns true if the token has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Returns the remaining time before the token expires
  Duration get remainingTime {
    final now = DateTime.now();
    return expiresAt.isAfter(now) ? expiresAt.difference(now) : Duration.zero;
  }

  /// Creates a copy of this token with the specified fields updated
  PasswordResetToken copyWith({
    String? id,
    String? userId,
    List<int>? tokenHash,
    String? type,
    DateTime? expiresAt,
    bool? used,
    DateTime? createdAt,
  }) {
    return PasswordResetToken(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tokenHash: tokenHash ?? this.tokenHash,
      type: type ?? this.type,
      expiresAt: expiresAt ?? this.expiresAt,
      used: used ?? this.used,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        tokenHash,
        type,
        expiresAt,
        used,
        createdAt,
      ];

  @override
  String toString() {
    return 'PasswordResetToken(id: $id, userId: $userId, type: $type, '
           'expiresAt: $expiresAt, used: $used, createdAt: $createdAt)';
  }
}

/// Enum for password reset token types
enum PasswordResetType {
  email,
  sms;

  String get value {
    switch (this) {
      case PasswordResetType.email:
        return 'email';
      case PasswordResetType.sms:
        return 'sms';
    }
  }

  static PasswordResetType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'email':
        return PasswordResetType.email;
      case 'sms':
        return PasswordResetType.sms;
      default:
        throw ArgumentError('Invalid password reset type: $type');
    }
  }
}
