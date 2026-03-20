import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:body_progress/providers/auth_provider.dart';
import 'package:body_progress/providers/profile_provider.dart';
import 'package:body_progress/providers/progress_provider.dart';
import 'package:body_progress/providers/photo_provider.dart';
import 'package:body_progress/providers/achievement_provider.dart';

/// App initialization state to track loading of all cached data
class AppInitState {
  final bool isInitialized;
  final bool isLoading;
  final String? error;

  const AppInitState({
    this.isInitialized = false,
    this.isLoading = false,
    this.error,
  });

  AppInitState copyWith({
    bool? isInitialized,
    bool? isLoading,
    String? error,
  }) => AppInitState(
    isInitialized: isInitialized ?? this.isInitialized,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
  );
}

/// Manages app-wide data initialization and caching
class AppInitNotifier extends StateNotifier<AppInitState> {
  final Ref _ref;

  AppInitNotifier(this._ref) : super(const AppInitState());

  /// Initialize all app data - call this once when user logs in or app starts with authenticated user
  Future<void> initializeAppData() async {
    if (state.isInitialized || state.isLoading) {
      return;
    }

    state = state.copyWith(isLoading: true);
    
    try {
      final user = _ref.read(authProvider).user;
      if (user == null || user.uid.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      // Load all data in parallel for maximum speed
      await Future.wait([
        _ref.read(profileProvider.notifier).loadProfile(),
        _ref.read(progressProvider.notifier).loadAndCacheBodyStats(),
        _ref.read(photoProvider.notifier).loadPhotos(),
      ], eagerError: false); // Continue even if some operations fail
      
      // Only recalculate achievements if profile exists
      final hasProfile = _ref.read(profileProvider).profile != null;
      if (hasProfile) {
        await _ref.read(achievementProvider.notifier).recalculateAllAchievements();
      }

      state = state.copyWith(isInitialized: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isInitialized: true, // Mark as initialized even on error to prevent retrying
      );
    }
  }

  /// Refresh cached data (call when user makes changes)
  Future<void> refreshCache() async {
    try {
      await Future.wait([
        _ref.read(profileProvider.notifier).loadProfile(),
        _ref.read(progressProvider.notifier).loadAndCacheBodyStats().then((_) {}),
        _ref.read(photoProvider.notifier).loadPhotos(),
      ]);
      
      // Recalculate achievements after data refresh
      await _ref.read(achievementProvider.notifier).recalculateAllAchievements();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Reset state (call on logout)
  void reset() {
    state = const AppInitState();
  }
}

final appInitProvider = StateNotifierProvider<AppInitNotifier, AppInitState>(
  (ref) => AppInitNotifier(ref),
);
