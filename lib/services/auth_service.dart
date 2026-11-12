import 'package:firebase_auth/firebase_auth.dart';

/// A lightweight, backend-agnostic view of the signed-in user, so the rest
/// of the app never depends on Firebase's [User] type directly.
class AppUser {
  final String id;
  final String? email;
  final String? displayName;

  AppUser({required this.id, this.email, this.displayName});
}

/// Thin wrapper around Firebase Auth so the rest of the app never talks
/// to `FirebaseAuth.instance` directly.
class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  static AuthService get instance => _instance;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  AppUser? _wrap(User? user) {
    if (user == null) return null;
    return AppUser(id: user.uid, email: user.email, displayName: user.displayName);
  }

  AppUser? get currentUser => _wrap(_auth.currentUser);

  // Login with email and password
  Future<AppUser?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _wrap(credential.user);
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<AppUser?> register(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (displayName != null && displayName.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
        await credential.user?.reload();
      }
      return _wrap(_auth.currentUser);
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      if (displayName != null) await user.updateDisplayName(displayName);
      if (photoUrl != null) await user.updatePhotoURL(photoUrl);
      await user.reload();
    } catch (e) {
      rethrow;
    }
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return currentUser != null;
  }

  // Stream of auth state changes (sign-in/sign-out only)
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().map(_wrap);
  }

  // Superset of authStateChanges that also fires on profile updates (e.g.
  // display name changes, or a cold-start session restoring with the full
  // profile arriving a moment after the initial uid-only user).
  Stream<AppUser?> userChanges() {
    return _auth.userChanges().map(_wrap);
  }
}
