import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:body_progress/models/achievement.dart';
import 'package:body_progress/services/milestone_service.dart';
import 'package:body_progress/providers/auth_provider.dart';
import 'package:body_progress/providers/profile_provider.dart';
import 'package:body_progress/providers/progress_provider.dart';
import 'package:body_progress/providers/photo_provider.dart';

class AchievementState {
  final List<Achievement> achievements;
  final List<Achievement> newAchievements; // Newly earned, pending celebration
  final bool isLoading;
  final String? errorMessage;

  const AchievementState({
    this.achievements = const [],
    this.newAchievements = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AchievementState copyWith({
    List<Achievement>? achievements,
    List<Achievement>? newAchievements,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) => AchievementState(
    achievements: achievements ?? this.achievements,
    newAchievements: newAchievements ?? this.newAchievements,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class AchievementNotifier extends StateNotifier<AchievementState> {
  final MilestoneService _milestoneService = MilestoneService();
  final Ref _ref;

  AchievementNotifier(this._ref) : super(const AchievementState());

  String? get _uid => _ref.read(authProvider).user?.uid;

  // ── Check for New Achievements ────────────────────────────────────────────

  Future<void> checkForNewAchievements() async {
    final uid = _uid;
    if (uid == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final profile = _ref.read(profileProvider).profile;
      final allStats = _ref.read(progressProvider).cachedBodyStats;
      final allPhotos = _ref.read(photoProvider).photos;

      final newAchievements = await _milestoneService.checkAchievements(
        userId: uid,
        profile: profile,
        allStats: allStats,
        allPhotos: allPhotos,
      );

      if (newAchievements.isNotEmpty) {
        // Load all achievements including the new ones
        final allAchievements = await _milestoneService.getUserAchievements(uid);
        
        state = state.copyWith(
          achievements: allAchievements,
          newAchievements: newAchievements,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Load Achievements ─────────────────────────────────────────────────────

  Future<void> loadAchievements() async {
    final uid = _uid;
    if (uid == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final achievements = await _milestoneService.getUserAchievements(uid);
      state = state.copyWith(
        achievements: achievements,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Recalculate All Achievements (cleanup) ───────────────────────────────

  Future<void> recalculateAllAchievements() async {
    final uid = _uid;
    if (uid == null) return;

    state = state.copyWith(isLoading: true);

    try {
      // Get old achievements before recalculating to detect new ones
      final oldEarnedIds = state.achievements.map((a) => a.type.id).toSet();
      
      final profile = _ref.read(profileProvider).profile;
      final allStats = _ref.read(progressProvider).cachedBodyStats;
      final allPhotos = _ref.read(photoProvider).photos;

      final allAchievements = await _milestoneService.recalculateAchievements(
        userId: uid,
        profile: profile,
        allStats: allStats,
        allPhotos: allPhotos,
      );

      // Find truly new achievements (earned now but not before)
      final newEarnedIds = allAchievements.map((a) => a.type.id).toSet();
      final trulyNewIds = newEarnedIds.difference(oldEarnedIds);
      final trulyNewAchievements = allAchievements
          .where((a) => trulyNewIds.contains(a.type.id))
          .toList();

      state = state.copyWith(
        achievements: allAchievements,
        newAchievements: trulyNewAchievements,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Clear New Achievements ────────────────────────────────────────────────

  void clearNewAchievements() {
    state = state.copyWith(newAchievements: []);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final achievementProvider =
    StateNotifierProvider<AchievementNotifier, AchievementState>(
        (ref) => AchievementNotifier(ref));
