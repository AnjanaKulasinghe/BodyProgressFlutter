import 'package:flutter/material.dart';
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/widgets/premium_widgets.dart';

class AppGuideView extends StatefulWidget {
  const AppGuideView({super.key});

  @override
  State<AppGuideView> createState() => _AppGuideViewState();
}

class _AppGuideViewState extends State<AppGuideView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        title: const Text(
          'App Guide',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Nunito',
          ),
        ),
        leading: IconButton(
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.brandPrimary,
          indicatorWeight: 3,
          labelColor: AppColors.brandPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: 'Nunito',
          ),
          tabs: const [
            Tab(text: 'Initial Setup'),
            Tab(text: 'Full Usage'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.appBackground, AppColors.cardBackground],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: const [
            _InitialSetupGuide(),
            _FullUsageGuide(),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// INITIAL SETUP GUIDE
// ═════════════════════════════════════════════════════════════════
class _InitialSetupGuide extends StatelessWidget {
  const _InitialSetupGuide();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [
                  Color(0x26FF6B35),
                  Color(0x1AFF9F1C),
                  AppColors.cardBackground,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppColors.brandPrimary.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: AppShadows.cardElevated,
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppGradients.brand,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.primaryGlow,
                  ),
                  child: const Icon(
                    Icons.flag_circle,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                ShaderMask(
                  shaderCallback: (bounds) => AppGradients.brand.createShader(bounds),
                  child: const Text(
                    'Initial Setup Guide',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Nunito',
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Get started with BodyProgress in 3 easy steps',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontFamily: 'Nunito',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Steps
          const _GuideStepCard(
            number: 1,
            icon: Icons.person_add,
            iconColor: Color(0xFF1B98E0),
            title: 'Sign Up / Log In',
            description:
                'Create an account or log in with your email. Verify your email if required to access all features.',
          ),
          const SizedBox(height: 16),
          const _GuideStepCard(
            number: 2,
            icon: Icons.person_pin,
            iconColor: Color(0xFF10B981),
            title: 'Profile Setup',
            description:
                'On first login, complete your profile with name, gender, height, weight, target weight, and fitness goal. This helps personalize your experience.',
          ),
          const SizedBox(height: 16),
          const _GuideStepCard(
            number: 3,
            icon: Icons.favorite,
            iconColor: Color(0xFFEF4444),
            title: 'Enable Health Sync (Optional)',
            description:
                'Go to Settings → Sync Health Data to connect with your device\'s health app (Health Kit on iOS, Google Fit on Android). This imports historical data and enables automatic stat tracking.',
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// FULL USAGE GUIDE
// ═════════════════════════════════════════════════════════════════
class _FullUsageGuide extends StatelessWidget {
  const _FullUsageGuide();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [
                  Color(0x261B98E0),
                  Color(0x1ABB6BD9),
                  AppColors.cardBackground,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFF1B98E0).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: AppShadows.cardElevated,
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1B98E0), Color(0xFFBB6BD9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x4D1B98E0),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF1B98E0), Color(0xFFBB6BD9)],
                  ).createShader(bounds),
                  child: const Text(
                    'Full Usage Guide',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Nunito',
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Everything you need to know about the app',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontFamily: 'Nunito',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tab Guides
          const _GuideTabCard(
            icon: Icons.home,
            iconColor: Color(0xFFFF6B35),
            title: 'Home Tab',
            features: [
              'View dashboard summary of latest stats',
              'Quick actions to log stats or upload photos',
              'See your recent activity and progress trends',
              'Achievement celebrations appear when you hit milestones',
            ],
          ),
          const SizedBox(height: 16),
          const _GuideTabCard(
            icon: Icons.bar_chart,
            iconColor: Color(0xFF10B981),
            title: 'Stats Tab',
            features: [
              'View all logged body measurements sorted by date',
              'Tap "Log Stats" to manually enter new data',
              'Edit or delete entries by tapping on them',
              'See trend indicators showing your progress',
              'Data automatically syncs with health apps if enabled',
            ],
          ),
          const SizedBox(height: 16),
          const _GuideTabCard(
            icon: Icons.show_chart,
            iconColor: Color(0xFF1B98E0),
            title: 'Progress Tab',
            features: [
              'Visualize progress with interactive charts',
              'Track weight, body fat %, BMI, and more',
              'Switch between metrics easily',
              'Pull down to refresh data',
              'Export your data as CSV or full report',
            ],
          ),
          const SizedBox(height: 16),
          const _GuideTabCard(
            icon: Icons.camera_alt,
            iconColor: Color(0xFFBB6BD9),
            title: 'Photos Tab',
            features: [
              'View all progress photos organized by type',
              'Tap photos to zoom in and view details',
              'Compare photos with before/after view',
              'Upload front, side, back, and custom photos',
              'Sample backgrounds help with consistent photos',
            ],
          ),
          const SizedBox(height: 16),
          const _GuideTabCard(
            icon: Icons.settings,
            iconColor: Color(0xFF707070),
            title: 'Settings Tab',
            features: [
              'Edit your profile details and fitness goals',
              'View and manage achievements and milestones',
              'Enable daily reminder notifications',
              'Toggle health data sync for your platform',
              'Access this guide and manage your account',
            ],
          ),
          const SizedBox(height: 20),

          // New Features Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.cardBackground,
              border: Border.all(
                color: const Color(0xFFFF6B35).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: AppShadows.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: AppGradients.brand,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.rocket_launch,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Key Features',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _TipRow(text: '🏆 Achievements: Earn milestones based on your progress'),
                const SizedBox(height: 12),
                const _TipRow(text: '🔔 Notifications: Set daily reminders to log stats'),
                const SizedBox(height: 12),
                const _TipRow(text: '📊 Export Data: Download your stats as CSV files'),
                const SizedBox(height: 12),
                const _TipRow(text: '✏️ Edit Profile: Update goals and personal info anytime'),
                const SizedBox(height: 12),
                const _TipRow(text: '📈 Progress Bars: See how close you are to each goal'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tips Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.cardBackground,
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: AppShadows.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFD60A), Color(0xFFF59E0B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lightbulb,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Tips & Best Practices',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _TipRow(text: 'Log stats regularly for accurate progress tracking'),
                const SizedBox(height: 12),
                const _TipRow(text: 'All your data is private, secure, and backed up'),
                const SizedBox(height: 12),
                const _TipRow(text: 'Enable health sync for automatic stat logging'),
                const SizedBox(height: 12),
                const _TipRow(text: 'Take photos in consistent lighting and poses'),
                const SizedBox(height: 12),
                const _TipRow(text: 'Set reminder notifications to stay consistent'),
                const SizedBox(height: 12),
                const _TipRow(text: 'Review achievements to celebrate your progress'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// SUPPORTING COMPONENTS
// ═════════════════════════════════════════════════════════════════
class _GuideStepCard extends StatelessWidget {
  final int number;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _GuideStepCard({
    required this.number,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.cardBackground,
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number Badge
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: AppGradients.brand,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.4,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideTabCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> features;

  const _GuideTabCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.cardBackground,
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: iconColor,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          height: 1.4,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String text;

  const _TipRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.star,
          color: Color(0xFFF59E0B),
          size: 16,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.4,
              fontFamily: 'Nunito',
            ),
          ),
        ),
      ],
    );
  }
}
