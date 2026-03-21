import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:body_progress/models/user_profile.dart';
import 'package:body_progress/models/body_stats.dart';
import 'package:body_progress/services/firestore_service.dart';
import 'package:body_progress/providers/auth_provider.dart';

class ProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? errorMessage;
  final bool showingAlert;
  final bool isEditing;
  final bool isNewProfile;
  // Form fields
  final String name;
  final String email;
  final DateTime dateOfBirth;
  final Gender gender;
  final String height;
  final ActivityLevel activityLevel;
  final FitnessGoal fitnessGoal;
  final String targetWeight;
  final String weight;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
    this.showingAlert = false,
    this.isEditing = false,
    this.isNewProfile = false,
    this.name = '',
    this.email = '',
    DateTime? dateOfBirth,
    this.gender = Gender.male,
    this.height = '',
    this.activityLevel = ActivityLevel.moderatelyActive,
    this.fitnessGoal = FitnessGoal.maintainWeight,
    this.targetWeight = '',
    this.weight = '',
  }) : dateOfBirth = dateOfBirth ?? const _DefaultDate();

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? errorMessage,
    bool? showingAlert,
    bool? isEditing,
    bool? isNewProfile,
    String? name,
    String? email,
    DateTime? dateOfBirth,
    Gender? gender,
    String? height,
    ActivityLevel? activityLevel,
    FitnessGoal? fitnessGoal,
    String? targetWeight,
    String? weight,
    bool clearError = false,
  }) => ProfileState(
    profile: profile ?? this.profile,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    showingAlert: clearError ? false : (showingAlert ?? this.showingAlert),
    isEditing: isEditing ?? this.isEditing,
    isNewProfile: isNewProfile ?? this.isNewProfile,
    name: name ?? this.name,
    email: email ?? this.email,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    gender: gender ?? this.gender,
    height: height ?? this.height,
    activityLevel: activityLevel ?? this.activityLevel,
    fitnessGoal: fitnessGoal ?? this.fitnessGoal,
    targetWeight: targetWeight ?? this.targetWeight,
    weight: weight ?? this.weight,
  );
}

class _DefaultDate implements DateTime {
  const _DefaultDate();
  // Required interface — uses 25 years ago as default
  @override
  noSuchMethod(Invocation i) =>
      DateTime.now().subtract(const Duration(days: 365 * 25));
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final FirestoreService _firestoreService = FirestoreService();
  final Ref _ref;

  ProfileNotifier(this._ref) : super(ProfileState(dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 25))));

  // ── Form Updates ──────────────────────────────────────────────────────────

  void setName(String v)                  => state = state.copyWith(name: v);
  void setEmail(String v)                 => state = state.copyWith(email: v);
  void setDateOfBirth(DateTime v)         => state = state.copyWith(dateOfBirth: v);
  void setGender(Gender v)                => state = state.copyWith(gender: v);
  void setHeight(String v)                => state = state.copyWith(height: v);
  void setActivityLevel(ActivityLevel v)  => state = state.copyWith(activityLevel: v);
  void setFitnessGoal(FitnessGoal v)      => state = state.copyWith(fitnessGoal: v);
  void setTargetWeight(String v)          => state = state.copyWith(targetWeight: v);
  void setWeight(String v)                => state = state.copyWith(weight: v);
  void setEditing(bool v)                 => state = state.copyWith(isEditing: v);
  void clearError()                       => state = state.copyWith(clearError: true);

  /// Reset provider to initial state (called on sign out)
  void reset() {
    state = ProfileState(dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 25)));
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadProfile() async {
    print('🟡 [ProfileProvider] >>> loadProfile - START <<<');
    final authState = _ref.read(authProvider);
    final uid = authState.user?.uid;
    final user = authState.user;
    if (uid == null || uid.isEmpty) {
      print('🟡 [ProfileProvider] uid is null or empty, returning');
      return;
    }

    print('🟡 [ProfileProvider] Loading profile for uid: $uid');
    print('🟡 [ProfileProvider] User displayName: ${user?.displayName}');
    print('🟡 [ProfileProvider] User email: ${user?.email}');

    try {
      final hasProfile = await _firestoreService.hasUserProfile(uid);
      
      debugPrint('[ProfileProvider] hasUserProfile result: $hasProfile');
      
      if (!hasProfile) {
        // Pre-populate from Firebase Auth - RESET all other fields to defaults
        final displayName = user?.displayName ?? '';
        final email = user?.email ?? '';
        
        debugPrint('[ProfileProvider] Creating new profile state - name: "$displayName", email: "$email"');
        
        state = ProfileState(
          dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 25)),
          isNewProfile: true,
          name: displayName,
          email: email,
        );
        debugPrint('[ProfileProvider] Created new profile state');
        return;
      }

      state = state.copyWith(isLoading: true);
      final profile = await _firestoreService.getUserProfile(uid);
      if (profile != null) {
        debugPrint('[ProfileProvider] Profile loaded: ${profile.name}');
        state = state.copyWith(
          profile: profile,
          isLoading: false,
          name: profile.name,
          email: profile.email,
          dateOfBirth: profile.dateOfBirth,
          gender: profile.gender,
          height: profile.height?.toStringAsFixed(1) ?? '',
          activityLevel: profile.activityLevel,
          fitnessGoal: profile.fitnessGoal,
          weight: profile.weight?.toStringAsFixed(1) ?? '',
          targetWeight: profile.targetWeight?.toStringAsFixed(1) ?? '',
        );
      } else {
        debugPrint('[ProfileProvider] Profile was null');
        state = state.copyWith(isLoading: false, isNewProfile: true);
      }
    } catch (e) {
      debugPrint('[ProfileProvider] loadProfile error: $e');
      state = state.copyWith(
        isLoading: false, 
        errorMessage: 'Error loading profile: ${e.toString()}', 
        showingAlert: false, // Don't show alert during background load
        isNewProfile: true,
      );
    }
  }

  /// Load current profile for editing (same as loadProfile but sets editing flag)
  Future<void> loadCurrentProfileForEdit() async {
    await loadProfile();
    state = state.copyWith(isEditing: true);
  }

  /// Load existing profile data into edit state without refetching
  void loadProfileIntoEditState(UserProfile profile) {
    state = state.copyWith(
      profile: profile,
      isEditing: true,
      name: profile.name,
      email: profile.email,
      dateOfBirth: profile.dateOfBirth,
      gender: profile.gender,
      height: profile.height?.toStringAsFixed(1) ?? '',
      activityLevel: profile.activityLevel,
      fitnessGoal: profile.fitnessGoal,
      weight: profile.weight?.toStringAsFixed(1) ?? '',
      targetWeight: profile.targetWeight?.toStringAsFixed(1) ?? '',
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<bool> saveProfile() async {
    final validationError = _validate();
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError, showingAlert: true);
      return false;
    }

    final authState = _ref.read(authProvider);
    final uid = authState.user?.uid;
    if (uid == null || uid.isEmpty) {
      state = state.copyWith(
        errorMessage: 'User not authenticated', 
        showingAlert: true,
      );
      return false;
    }

    state = state.copyWith(isLoading: true);
    try {
      final profile = UserProfile(
        id: state.profile?.id,
        userId: uid,
        email: state.email,
        name: state.name,
        dateOfBirth: state.dateOfBirth,
        gender: state.gender,
        height: double.tryParse(state.height),
        activityLevel: state.activityLevel,
        fitnessGoal: state.fitnessGoal,
        targetWeight: double.tryParse(state.targetWeight),
        weight: double.tryParse(state.weight),
        createdAt: state.profile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateUserProfile(profile);
      
      // Create initial body stats entry from profile data (only for new profiles)
      if (state.isNewProfile && profile.weight != null && profile.height != null) {
        try {
          final bmi = profile.weight! / (profile.height! / 100 * profile.height! / 100);
          final initialStats = BodyStats(
            userId: uid,
            date: DateTime.now(),
            weight: profile.weight!,
            bmi: bmi,
            notes: 'Initial measurement from profile setup',
            source: DataSource.manual,
            createdAt: DateTime.now(),
          );
          await _firestoreService.saveBodyStats(initialStats);
        } catch (e) {
          // Non-fatal - profile still saved successfully
        }
      }
      
      state = state.copyWith(
        profile: profile, isLoading: false, isEditing: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Error saving profile: ${e.toString()}', showingAlert: true);
      return false;
    }
  }

  // ── Validation ────────────────────────────────────────────────────────────

  String? _validate() {
    if (state.name.trim().isEmpty) return 'Name is required';
    if (state.email.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$')
        .hasMatch(state.email)) return 'Enter a valid email';
    
    // Weight validation
    if (state.weight.isNotEmpty) {
      final w = double.tryParse(state.weight);
      if (w == null || w <= 0 || w >= 500) return 'Enter a valid weight (1-500 kg)';
    } else if (state.isNewProfile) {
      // Only require weight for new profiles (initial stats entry)
      return 'Current weight is required';
    }
    
    // Target weight is mandatory for milestone calculations
    if (state.targetWeight.isEmpty) return 'Target weight is required';
    final tw = double.tryParse(state.targetWeight);
    if (tw == null || tw <= 0 || tw >= 500) return 'Enter a valid target weight (1-500 kg)';
    
    // Height validation
    if (state.height.isNotEmpty) {
      final h = double.tryParse(state.height);
      if (h == null || h <= 0 || h >= 250) return 'Enter a valid height (1-250 cm)';
    } else if (state.isNewProfile) {
      // Only require height for new profiles (BMI calculation)
      return 'Height is required';
    }
    
    return null;
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
    (ref) => ProfileNotifier(ref));
