import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:body_progress/models/user_profile.dart';
import 'package:body_progress/services/auth_service.dart';
import 'package:body_progress/services/firestore_service.dart';
import 'package:body_progress/providers/profile_provider.dart';
import 'package:body_progress/providers/app_init_provider.dart';
import 'package:body_progress/providers/progress_provider.dart';
import 'package:body_progress/providers/photo_provider.dart';

// ── Auth Stream Provider ──────────────────────────────────────────────────────

final authStreamProvider = StreamProvider<User?>((ref) {
  return AuthService().authStateChanges;
});

// ── Auth Notifier ─────────────────────────────────────────────────────────────

class AuthState {
  final User? user;
  final bool isLoading;
  final String? errorMessage;
  final bool showingAlert;
  // Form fields
  final String email;
  final String password;
  final String confirmPassword;
  final String name;
  final String resetEmail;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.showingAlert = false,
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.name = '',
    this.resetEmail = '',
  });

  bool get isAuthenticated => user != null;
  bool get isEmailVerified => user?.emailVerified ?? false;

  bool get canProceed {
    return isAuthenticated;
  }

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? errorMessage,
    bool? showingAlert,
    String? email,
    String? password,
    String? confirmPassword,
    String? name,
    String? resetEmail,
    bool clearError = false,
  }) => AuthState(
    user: user ?? this.user,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    showingAlert: clearError ? false : (showingAlert ?? this.showingAlert),
    email: email ?? this.email,
    password: password ?? this.password,
    confirmPassword: confirmPassword ?? this.confirmPassword,
    name: name ?? this.name,
    resetEmail: resetEmail ?? this.resetEmail,
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState()) {
    _authService.authStateChanges.listen((user) {
      state = state.copyWith(user: user);
    });
  }

  // ── Form updates ──────────────────────────────────────────────────────────

  void setEmail(String v)           => state = state.copyWith(email: v);
  void setPassword(String v)        => state = state.copyWith(password: v);
  void setConfirmPassword(String v) => state = state.copyWith(confirmPassword: v);
  void setName(String v)            => state = state.copyWith(name: v);
  void setResetEmail(String v)      => state = state.copyWith(resetEmail: v);
  void clearError()                 => state = state.copyWith(clearError: true);

  // ── Validation ────────────────────────────────────────────────────────────

  String? validateSignUp() {
    if (state.name.trim().isEmpty) return 'Name is required';
    if (state.email.trim().isEmpty) return 'Email is required';
    if (!_isValidEmail(state.email)) return 'Enter a valid email address';
    if (state.password.length < 6) return 'Password must be at least 6 characters';
    if (state.password != state.confirmPassword) return 'Passwords do not match';
    return null;
  }

  String? validateSignIn() {
    if (state.email.trim().isEmpty) return 'Email is required';
    if (state.password.isEmpty) return 'Password is required';
    return null;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,64}$')
        .hasMatch(email);
  }

  // ── Auth Actions ──────────────────────────────────────────────────────────

  Future<bool> signUp() async {
    final error = validateSignUp();
    if (error != null) { _setError(error); return false; }
    state = state.copyWith(isLoading: true);
    try {
      await _authService.signUp(
        email: state.email, password: state.password, name: state.name);
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e));
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      _setError(e.toString());
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> signIn() async {
    final error = validateSignIn();
    if (error != null) { _setError(error); return false; }
    state = state.copyWith(isLoading: true);
    try {
      await _authService.signIn(email: state.email, password: state.password);
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e));
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      _setError(e.toString());
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.signInWithApple();
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } catch (e) {
      _setError(e.toString());
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.signInWithGoogle();
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } catch (e) {
      _setError(e.toString());
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    // Clear all provider states on sign out
    _ref.read(profileProvider.notifier).reset();
    _ref.read(appInitProvider.notifier).reset();
    _ref.read(progressProvider.notifier).reset();
    _ref.read(photoProvider.notifier).reset();
  }

  Future<bool> sendPasswordReset() async {
    if (state.resetEmail.trim().isEmpty) { _setError('Enter your email address'); return false; }
    try {
      await _authService.sendPasswordResetEmail(state.resetEmail);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e));
      return false;
    }
  }

  Future<void> resendVerificationEmail() async {
    // No-op: Email verification disabled for simpler user experience
    // Method kept for compatibility with EmailVerificationView
  }

  Future<void> reloadUser() => _authService.reloadUser();

  Future<bool> hasUserProfile() async {
    final uid = state.user?.uid;
    if (uid == null) {
      return false;
    }
    try {
      debugPrint('[AuthProvider] Checking profile for uid: $uid');
      final result = await _firestoreService.hasUserProfile(uid).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          debugPrint('[AuthProvider] hasUserProfile timeout after 20s');
          return false;
        },
      );
      debugPrint('[AuthProvider] hasUserProfile result: $result');
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<UserProfile?> getUserProfile() async {
    final uid = state.user?.uid;
    if (uid == null) return null;
    return _firestoreService.getUserProfile(uid);
  }

  /// Delete account with optional re-authentication (password required for email/password accounts)
  Future<void> deleteAccount({String? password}) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final uid = state.user?.uid;
      if (uid == null) {
        throw Exception('No authenticated user to delete');
      }
      
      // Re-authenticate if password provided (for email/password users)
      if (password != null && password.isNotEmpty) {
        await _authService.reauthenticateWithPassword(password);
      }
      
      // Delete all user data from Firestore
      await _firestoreService.batchDeleteUserData(uid);
      
      // Delete the Firebase Auth account
      await _authService.deleteAccount();
      
      state = state.copyWith(isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _setError('Failed to delete account: ${e.toString()}');
      rethrow;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setError(String message) {
    state = state.copyWith(errorMessage: message, showingAlert: true);
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use': return 'An account already exists with this email';
      case 'invalid-email':        return 'Invalid email address';
      case 'weak-password':        return 'Password is too weak';
      case 'user-not-found':       return 'No account found with this email';
      case 'wrong-password':       return 'Incorrect password';
      case 'too-many-requests':    return 'Too many attempts. Try again later';
      case 'network-request-failed': return 'No internet connection';
      default: return e.message ?? 'An error occurred';
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);
