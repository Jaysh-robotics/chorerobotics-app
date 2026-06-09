import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_initializer.dart';

class AuthServiceException implements Exception {
  final String message;
  final String? code;
  AuthServiceException(this.message, {this.code});
  @override
  String toString() => message;
}

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get currentUser => FirebaseInitializer.isInitialized ? _auth.currentUser : null;

  Stream<User?> get authStateChanges =>
      FirebaseInitializer.isInitialized ? _auth.authStateChanges() : const Stream.empty();

  bool get isSignedIn => currentUser != null;

  void _assertInitialized() {
    if (!FirebaseInitializer.isInitialized) {
      throw AuthServiceException(
        'Firebase is not configured. Run `flutterfire configure`.',
        code: 'firebase-not-initialized',
      );
    }
  }

  Future<User> signInWithEmail(String email, String password) async {
    _assertInitialized();
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) throw AuthServiceException('No user returned.');
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(_humanMessage(e), code: e.code);
    }
  }

  Future<User> signUpWithEmail(String email, String password) async {
    _assertInitialized();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) throw AuthServiceException('No user returned.');
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(_humanMessage(e), code: e.code);
    }
  }

  Future<User> signInWithGoogle() async {
    _assertInitialized();
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw AuthServiceException('Google sign-in cancelled.', code: 'cancelled');
      }
      final auth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      final user = cred.user;
      if (user == null) throw AuthServiceException('No user returned.');
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(_humanMessage(e), code: e.code);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    _assertInitialized();
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(_humanMessage(e), code: e.code);
    }
  }

  Future<void> signOut() async {
    if (!FirebaseInitializer.isInitialized) return;
    await _auth.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Ignore — user may not have signed in via Google.
    }
  }

  String _humanMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a few minutes.';
      default:
        return e.message ?? 'Authentication failed (${e.code}).';
    }
  }
}
