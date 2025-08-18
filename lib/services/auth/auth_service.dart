import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:savessa/services/database/database_service.dart';

/// Auth service: Firebase session + Postgres mirror for role.
class AuthService with ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _auth.userChanges().listen((_) async {
      await _mirrorAndResolveRole();
      notifyListeners();
    });
  }

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final DatabaseService _db = DatabaseService();

  String _role = 'member';
  String get role => _role; // 'admin' or 'member'
  bool _roleResolved = false;
  bool get roleResolved => _roleResolved;
  String? _postgresUserId;
  String? get postgresUserId => _postgresUserId;

  fb.User? get currentUser => _auth.currentUser;
  Stream<fb.User?> get authStateChanges => _auth.authStateChanges();

  Future<void> ensureSignedInAnonymously() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _role = 'member';
    _roleResolved = false;
  }

  Future<void> _mirrorAndResolveRole() async {
    final u = _auth.currentUser;
    if (u == null) {
      _roleResolved = true;
      _role = 'member';
      return;
    }
    try {
      // Mirror
      await _db.upsertUserMirror(
        firebaseUid: u.uid,
        email: u.email,
        phone: u.phoneNumber,
      );
      // Load user record
      final row = await _db.getUserByFirebaseUid(u.uid);
      _postgresUserId = row?['id']?.toString();
      final dbRole = row?['role']?.toString();
      _role = (dbRole == 'admin' || dbRole == 'member') ? dbRole! : 'member';
      _roleResolved = true;
    } catch (e) {
      debugPrint('AuthService role resolve error: $e');
      _role = 'member';
      _roleResolved = true;
    }
  }
}
