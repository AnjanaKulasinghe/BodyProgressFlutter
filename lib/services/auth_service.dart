import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';

/// Handles all Firebase Authentication operations:
/// - Email/Password sign-up and sign-in
/// - Apple Sign In (iOS)
/// - Google Sign In (Android + iOS)
/// - Email verification, password reset
/// - Account deletion
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── State ──────────────────────────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isAuthenticated => currentUser != null;

  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  bool get isSignedInWithApple => currentUser?.providerData
          .any((p) => p.providerId == 'apple.com') ?? false;

  /// A user can proceed if authenticated (email verification disabled)
  bool get canProceed {
    return isAuthenticated;
  }

  // ── Email / Password ───────────────────────────────────────────────────────

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(name.trim());
    // Email verification disabled for simpler user experience
    // await cred.user?.sendEmailVerification();
    return cred;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  // Email verification disabled - method kept for compatibility but does nothing
  Future<void> sendEmailVerification() async {
    // No-op: Email verification disabled for simpler user experience
  }

  Future<void> reloadUser() => _auth.currentUser?.reload() ?? Future.value();

  Future<void> deleteAccount() => currentUser?.delete() ?? Future.value();

  // ── Apple Sign In (iOS + macOS — also works on Android via web) ───────────

  Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode, // Providing a valid string to fulfill the credentials check
      rawNonce: rawNonce,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);
    
    // Update display name from Apple-provided data if available
    final user = userCredential.user;
    if (user != null && user.displayName == null) {
      final givenName = appleCredential.givenName;
      final familyName = appleCredential.familyName;
      if (givenName != null && familyName != null) {
        final fullName = '$givenName $familyName'.trim();
        await user.updateDisplayName(fullName);
      }
    }
    
    return userCredential;
  }

  // ── Google Sign In (Android primary, iOS secondary) ───────────────────────

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google Sign In cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  // ── Display name refresh ───────────────────────────────────────────────────

  Future<String?> refreshUserName() async {
    await currentUser?.reload();
    return _auth.currentUser?.displayName;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
