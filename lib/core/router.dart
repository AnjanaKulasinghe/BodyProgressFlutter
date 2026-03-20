import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:body_progress/providers/auth_provider.dart';
import 'package:body_progress/views/auth/auth_view.dart';
import 'package:body_progress/views/auth/email_verification_view.dart';
import 'package:body_progress/views/onboarding/onboarding_view.dart';
import 'package:body_progress/views/tutorial/tutorial_view.dart';
import 'package:body_progress/views/profile/profile_setup_view.dart';
import 'package:body_progress/views/home/home_view.dart';
import 'package:body_progress/views/photos/photos_view.dart';
import 'package:body_progress/views/photos/photo_upload_journey_view.dart';
import 'package:body_progress/views/photos/photo_comparison_view.dart';
import 'package:body_progress/views/stats/stats_view.dart';
import 'package:body_progress/views/stats/stats_entry_view.dart';
import 'package:body_progress/views/progress/progress_view.dart';
import 'package:body_progress/views/settings/settings_view.dart';
import 'package:body_progress/views/splash/loading_screen.dart';
import 'package:body_progress/widgets/main_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Route name constants
class AppRoutes {
  static const splash        = '/';
  static const auth          = '/auth';
  static const verifyEmail   = '/verify-email';
  static const onboarding    = '/onboarding';
  static const profileSetup  = '/profile-setup';
  static const tutorial      = '/tutorial';
  static const home          = '/home';
  static const photos        = '/photos';
  static const photoUpload   = '/photos/upload';
  static const photoCompare  = '/photos/compare';
  static const stats         = '/stats';
  static const statsEntry    = '/stats/entry';
  static const progress      = '/progress';
  static const settings      = '/settings';
}

GoRouter createRouter(WidgetRef ref) {
  // We need a refreshListenable for GoRouter to automatically re-evaluate redirects on auth changes.
  // We can achieve this by creating a simple ValueNotifier that updates when the stream emits.
  final authNotifier = ValueNotifier<bool>(false);
  ref.listen(authStreamProvider, (_, next) {
    authNotifier.value = next.value != null;
  });

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) async {
      try {
        final path = state.matchedLocation;

        // Always allow splash, tutorial, and loading-related routes
        if (path == AppRoutes.splash || path == AppRoutes.tutorial) return null;

        // Use the stream-based provider to get a fresh auth state
        final authStream = ref.read(authStreamProvider);
        final user = authStream.valueOrNull;
        final isAuthenticated = user != null;

        // Redirect to auth if not authenticated
        if (!isAuthenticated) return AppRoutes.auth;

        // Check if user has a profile in Firestore
        final authNotifier = ref.read(authProvider.notifier);
        final hasProfile = await authNotifier.hasUserProfile();
        
        // If user has a profile, they can access the app
        if (hasProfile) {
          // Existing user - skip onboarding and profile setup
          if (path == AppRoutes.onboarding || path == AppRoutes.profileSetup) {
            return AppRoutes.splash; // Go to loading screen to load data
          }
          if (path == AppRoutes.auth || path == AppRoutes.verifyEmail) {
            return AppRoutes.splash; // Go to loading screen to load data
          }
          return null; // Allow access to requested route
        }

        // New user flow - no onboarding, just profile setup then loading
        if (path == AppRoutes.profileSetup) return null; // Allow profile setup
        
        // If trying to access protected routes without profile, redirect to profile setup
        return AppRoutes.profileSetup;
      } catch (e) {
        print('Router redirect error: $e');
        return AppRoutes.auth;
      }
    },
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const LoadingScreen(),
      ),

      // Auth (unauthenticated)
      GoRoute(
        path: AppRoutes.auth,
        builder: (_, __) => const AuthView(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (_, __) => const EmailVerificationView(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingView(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (_, __) => const ProfileSetupView(),
      ),
      GoRoute(
        path: AppRoutes.tutorial,
        builder: (_, __) => const TutorialView(),
      ),

      // Main Tab Shell with Stateful Navigation (preserves state between tabs)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, __) => const HomeView(),
              ),
            ],
          ),
          // Branch 1: Photos
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.photos,
                builder: (_, __) => const PhotosView(),
                routes: [
                  GoRoute(
                    path: 'upload',
                    builder: (_, __) => const PhotoUploadJourneyView(),
                  ),
                  GoRoute(
                    path: 'compare',
                    builder: (_, __) => const PhotoComparisonView(),
                  ),
                ],
              ),
            ],
          ),
          // Branch 2: Stats
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.stats,
                builder: (_, __) => const StatsView(),
                routes: [
                  GoRoute(
                    path: 'entry',
                    builder: (_, state) {
                      return const StatsEntryView();
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 3: Progress
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.progress,
                builder: (_, __) => const ProgressView(),
              ),
            ],
          ),
          // Branch 4: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (_, __) => const SettingsView(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
