import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:savessa/services/database/database_service.dart';

/// Auth service: Firebase session + Postgres mirror for role.
class AuthService with ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    try {
      _auth.userChanges().listen((_) async {
        await _mirrorAndResolveRole();
        notifyListeners();
      });
      _firebaseAvailable = true;
    } catch (e) {
      debugPrint('Firebase Auth not available: $e');
      _firebaseAvailable = false;
      // Continue without Firebase auth functionality
      _roleResolved = true;
    }
  }

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final DatabaseService _db = DatabaseService();
  bool _firebaseAvailable = false;

  String _role = 'member';
  String get role => _role; // 'admin' or 'member'
  bool _roleResolved = false;
  bool get roleResolved => _roleResolved;
  String? _postgresUserId;
  String? get postgresUserId => _postgresUserId;

  fb.User? get currentUser => _firebaseAvailable ? _auth.currentUser : null;
  Stream<fb.User?> get authStateChanges => _firebaseAvailable ? _auth.authStateChanges() : Stream.value(null);

  Future<void> ensureSignedInAnonymously() async {
    if (!_firebaseAvailable) {
      debugPrint('Firebase Auth not available, skipping anonymous sign-in');
      return;
    }
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
    } catch (e) {
      debugPrint('Failed to sign in anonymously: $e');
    }
  }

  Future<void> signOut() async {
    if (_firebaseAvailable) {
      try {
        await _auth.signOut();
      } catch (e) {
        debugPrint('Failed to sign out from Firebase: $e');
      }
    }
    _role = 'member';
    _roleResolved = false;
    _postgresUserId = null;
  }

  // Allows DB-auth flow to set the session details without Firebase
  void setPostgresSessionFromDb(Map<String, dynamic> userRow) {
    _postgresUserId = userRow['id']?.toString();
    final dbRole = userRow['role']?.toString();
    _role = (dbRole == 'admin' || dbRole == 'member') ? dbRole! : 'member';
    _roleResolved = true;
    notifyListeners();
  }

  Future<void> _mirrorAndResolveRole() async {
    final u = _auth.currentUser;
    if (u == null) {
      _roleResolved = true;
      _role = 'member';
      _postgresUserId = null;
      return;
    }
    try {
      // Resolve role from Postgres using email or phone; do not upsert implicitly.
      Map<String, dynamic>? row;
      if (u.email != null && u.email!.isNotEmpty) {
        row = await _db.getUserByEmail(u.email!);
      }
      row ??= (u.phoneNumber != null && u.phoneNumber!.isNotEmpty)
          ? await _db.getUserByEmailOrPhone(u.phoneNumber!)
          : null;

      if (row == null) {
        // No matching Postgres user; mark unresolved but default role
        _postgresUserId = null;
        _role = 'member';
      } else {
        _postgresUserId = row['id']?.toString();
        final dbRole = row['role']?.toString();
        _role = (dbRole == 'admin' || dbRole == 'member') ? dbRole! : 'member';
      }
      _roleResolved = true;
    } catch (e) {
      debugPrint('AuthService role resolve error: $e');
      _role = 'member';
      _roleResolved = true;
    }
  }
}
