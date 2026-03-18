import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/core/router.dart';
import 'package:body_progress/models/body_stats.dart';
import 'package:body_progress/models/user_profile.dart';
import 'package:body_progress/providers/auth_provider.dart';
import 'package:body_progress/providers/profile_provider.dart';
import 'package:body_progress/providers/progress_provider.dart';
import 'package:body_progress/providers/photo_provider.dart';
import 'package:body_progress/providers/app_init_provider.dart';
import 'package:body_progress/providers/achievement_provider.dart';
import 'package:body_progress/widgets/celebration_overlay.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});
  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    // Data is already loaded by splash screen, no need to load again
    // Just ensure it's initialized (in case user navigated directly here)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appInit = ref.read(appInitProvider);
      if (!appInit.isInitialized && !appInit.isLoading) {
        ref.read(appInitProvider.notifier).initializeAppData();
      }
      // Achievement recalculation is handled by app init
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(profileProvider);
    final progressState = ref.watch(progressProvider);
    final photoState = ref.watch(photoProvider);

    // Listen for new achievements and show celebration
    ref.listen<AchievementState>(achievementProvider, (previous, next) {
      if (next.newAchievements.isNotEmpty && mounted) {
        // Show celebration for the first new achievement
        final achievement = next.newAchievements.first;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => CelebrationOverlay(
            achievement: achievement,
            onDismiss: () {
              Navigator.of(context).pop();
              // Clear the new achievements after showing
              ref.read(achievementProvider.notifier).clearNewAchievements();
              
              // If there are more achievements, show them one by one
              if (next.newAchievements.length > 1) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  final remaining = next.newAchievements.skip(1).toList();
                  if (remaining.isNotEmpty && mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => CelebrationOverlay(
                        achievement: remaining.first,
                        onDismiss: () {
                          Navigator.of(context).pop();
                          ref.read(achievementProvider.notifier).clearNewAchievements();
                        },
                      ),
                    );
                  }
                });
              }
            },
          ),
        );
      }
    });

    final profile = profileState.profile;
    final stats = progressState.cachedBodyStats;
    
    // Get latest weight and BMI from the most recent stat (stats are sorted descending)
    final latestWeight = stats.isNotEmpty ? stats.first.weight : null;
    double? latestBmi = stats.isNotEmpty ? stats.first.bmi : null;
    
    // Calculate BMI if not available but we have weight and height
    if (latestBmi == null && latestWeight != null && profile?.height != null) {
      final heightInMeters = profile!.height! / 100; // Convert cm to meters
      latestBmi = latestWeight / (heightInMeters * heightInMeters);
    }
    
    final firstName = (profile?.name ?? authState.user?.displayName ?? '').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.appBackground, AppColors.cardBackground],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: AppColors.brandPrimary,
            backgroundColor: AppColors.cardBackground,
            child: CustomScrollView(
              slivers: [
                // Premium Welcome Header
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _WelcomeHeader(
                      firstName: firstName,
                      greeting: _getGreeting(),
                      emoji: _getGreetingEmoji(),
                      onAvatarTap: () => context.go(AppRoutes.settings),
                    ),
                  ),
                ),

                // Content with animations
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 24),
                      
                      // Quick Stats Cards
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _QuickStatsSection(
                          weight: latestWeight,
                          bmi: latestBmi,
                          photoCount: photoState.photos.length,
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // Quick Actions
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _QuickActionsSection(
                          onLogStats: () => context.go(AppRoutes.statsEntry),
                          onAddPhoto: () => context.go(AppRoutes.photoUpload),
                          onViewProgress: () => context.go(AppRoutes.progress),
                          onComparePhotos: () => context.go(AppRoutes.photoCompare),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Recent Stats
                      if (stats.isNotEmpty) ...[
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: _SectionHeader(
                            title: 'Recent Activity',
                            onTap: () => context.go(AppRoutes.stats),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...stats.take(3).map((s) => FadeTransition(
                          opacity: _fadeAnimation,
                          child: _RecentStatItem(stat: s),
                        )),
                      ],
                      
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    // Use the app init provider's refresh method for consistent caching
    await ref.read(appInitProvider.notifier).refreshCache();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '👋';
    return '🌙';
  }
}

// ═════════════════════════════════════════════════════════════════
// PREMIUM WELCOME HEADER (Matches iOS)
// ═════════════════════════════════════════════════════════════════
class _WelcomeHeader extends StatelessWidget {
  final String firstName;
  final String greeting;
  final String emoji;
  final VoidCallback onAvatarTap;

  const _WelcomeHeader({
    required this.firstName,
    required this.greeting,
    required this.emoji,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              Color(0x26FF6B35),  // brandPrimary with opacity
              Color(0x1AFF9F1C),  // brandAccent with opacity
              AppColors.darkCardBackground,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            width: 1,
            color: const Color(0x4DFF6B35),
          ),
          boxShadow: AppShadows.cardElevated,
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Premium avatar with gradient ring
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.brand,
                      boxShadow: AppShadows.primaryGlow,
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.darkCardBackground,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppGradients.brand,
                        ),
                        child: Center(
                          child: Text(
                            firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Greeting
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            greeting,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Nunito',
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        firstName.isEmpty ? 'Welcome!' : firstName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// QUICK STATS SECTION (Premium Cards)
// ═════════════════════════════════════════════════════════════════
class _QuickStatsSection extends StatelessWidget {
  final double? weight;
  final double? bmi;
  final int photoCount;

  const _QuickStatsSection({
    required this.weight,
    required this.bmi,
    required this.photoCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PremiumStatCard(
            label: 'Weight',
            value: weight != null ? '${weight!.toStringAsFixed(1)} kg' : '--',
            icon: Icons.monitor_weight_outlined,
            gradientColors: const [Color(0xFFFF6B35), Color(0xFFFF9F1C)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PremiumStatCard(
            label: 'BMI',
            value: bmi != null ? bmi!.toStringAsFixed(1) : '--',
            icon: Icons.straighten_outlined,
            gradientColors: const [Color(0xFF1B98E0), Color(0xFF0066CC)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PremiumStatCard(
            label: 'Photos',
            value: photoCount.toString(),
            icon: Icons.photo_library_outlined,
            gradientColors: const [Color(0xFFFF9F1C), Color(0xFFFFD60A)],
          ),
        ),
      ],
    );
  }
}

class _PremiumStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;

  const _PremiumStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            gradientColors[0].withOpacity(0.15),
            gradientColors[1].withOpacity(0.05),
            AppColors.cardBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          width: 1,
          color: gradientColors[0].withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// QUICK ACTIONS SECTION (Premium Buttons)
// ═════════════════════════════════════════════════════════════════
class _QuickActionsSection extends StatelessWidget {
  final VoidCallback onLogStats;
  final VoidCallback onAddPhoto;
  final VoidCallback onViewProgress;
  final VoidCallback onComparePhotos;

  const _QuickActionsSection({
    required this.onLogStats,
    required this.onAddPhoto,
    required this.onViewProgress,
    required this.onComparePhotos,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _PremiumActionCard(
              icon: Icons.straighten,
              label: 'Log Stats',
              gradientColors: const [Color(0xFFFF6B35), Color(0xFFFF9F1C)],
              onTap: onLogStats,
            ),
            _PremiumActionCard(
              icon: Icons.camera_alt,
              label: 'Add Photo',
              gradientColors: const [Color(0xFF1B98E0), Color(0xFF0066CC)],
              onTap: onAddPhoto,
            ),
            _PremiumActionCard(
              icon: Icons.show_chart,
              label: 'View Progress',
              gradientColors: const [Color(0xFFFF9F1C), Color(0xFFFFD60A)],
              onTap: onViewProgress,
            ),
            _PremiumActionCard(
              icon: Icons.compare,
              label: 'Compare',
              gradientColors: const [Color(0xFF10B981), Color(0xFF8BC34A)],
              onTap: onComparePhotos,
            ),
          ],
        ),
      ],
    );
  }
}

class _PremiumActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _PremiumActionCard({
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              gradientColors[0].withOpacity(0.2),
              gradientColors[1].withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            width: 1,
            color: gradientColors[0].withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// SECTION HEADER
// ═════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _SectionHeader({
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito',
            ),
          ),
          if (onTap != null)
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// RECENT STAT ITEM (Premium Card)
// ═════════════════════════════════════════════════════════════════
class _RecentStatItem extends StatelessWidget {
  final BodyStats stat;

  const _RecentStatItem({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0x1AFF6B35),
            Color(0x0DFF9F1C),
            AppColors.cardBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          width: 1,
          color: const Color(0x33FF6B35),
        ),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppShadows.primaryGlow,
            ),
            child: const Icon(
              Icons.monitor_weight_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.yMMMd().format(stat.date),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stat.weight.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
          if (stat.bmi != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppGradients.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'BMI ${stat.bmi!.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
