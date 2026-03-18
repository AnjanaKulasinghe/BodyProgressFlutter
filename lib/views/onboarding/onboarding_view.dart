import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/core/router.dart';
import 'package:body_progress/widgets/loading_button.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});
  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _fadeAnimations;

  static const _pages = [
    _OnboardingPage(
      icon: '👋',
      title: 'Welcome to BodyProgress',
      subtitle: 'Track your fitness journey with progress photos, body measurements, and visual comparisons. Let\'s explore the features.',
      gradient: LinearGradient(
        colors: [Color(0xFFFF6B35), Color(0xFFFF9F1C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      iconBackgroundColor: Color(0xFFFF6B35),
    ),
    _OnboardingPage(
      icon: '🏠',
      title: 'Home Dashboard',
      subtitle: 'Your central hub displays recent photos, latest stats, and quick actions. Start your day by checking your progress at a glance.',
      gradient: LinearGradient(
        colors: [Color(0xFF1B98E0), Color(0xFF0066CC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      iconBackgroundColor: Color(0xFF1B98E0),
    ),
    _OnboardingPage(
      icon: '📸',
      title: 'Progress Photos',
      subtitle: 'Capture front, side, back, and custom angle photos. Use the comparison slider to reveal your transformation over time.',
      gradient: LinearGradient(
        colors: [Color(0xFFBB6BD9), Color(0xFF9B51E0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      iconBackgroundColor: Color(0xFFBB6BD9),
    ),
    _OnboardingPage(
      icon: '📊',
      title: 'Body Measurements',
      subtitle: 'Log your weight, body fat, muscle mass, and measurements. Sync with your device\'s health app for automatic tracking.',
      gradient: LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF8BC34A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      iconBackgroundColor: Color(0xFF10B981),
    ),
    _OnboardingPage(
      icon: '📈',
      title: 'Track Your Progress',
      subtitle: 'Visualize your journey with beautiful charts and side-by-side photo comparisons. See how far you\'ve come!',
      gradient: LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFFF9F1C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      iconBackgroundColor: Color(0xFFF59E0B),
    ),
    _OnboardingPage(
      icon: '🏆',
      title: 'Earn Achievements',
      subtitle: 'Celebrate your milestones! Earn trophies as you hit 10%, 25%, 50%, and more of your goal. Track consistency streaks and photo uploads.',
      gradient: LinearGradient(
        colors: [Color(0xFFFFC107), Color(0xFFFF9800)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      iconBackgroundColor: Color(0xFFFFC107),
    ),
    _OnboardingPage(
      icon: '✨',
      title: 'Ready to Begin!',
      subtitle: 'You\'re all set! Start by setting up your profile, taking your first progress photo, and logging your initial measurements.',
      gradient: LinearGradient(
        colors: [Color(0xFFFF6B35), Color(0xFF1B98E0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      iconBackgroundColor: Color(0xFFFF6B35),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationControllers = List.generate(
      _pages.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );
    _fadeAnimations = _animationControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();
    _animationControllers[0].forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedOnboarding', true);
    if (mounted) context.go(AppRoutes.profileSetup);
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _animationControllers[page].forward();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              // Top Bar with Skip and Back
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _completeOnboarding,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.textTertiary.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ),
                    if (_currentPage > 0)
                      GestureDetector(
                        onTap: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppGradients.brand,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => FadeTransition(
                    opacity: _fadeAnimations[i],
                    child: _OnboardingPageWidget(page: _pages[i]),
                  ),
                ),
              ),

              // Page Indicator (Premium animated dots)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    final isActive = _currentPage == i;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? AppGradients.brand
                            : null,
                        color: isActive ? null : AppColors.textTertiary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.brandPrimary.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ),

              // Bottom Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: _currentPage < _pages.length - 1
                    ? LoadingButton(
                        label: 'Next',
                        onPressed: () async {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: Icons.arrow_forward,
                      )
                    : LoadingButton(
                        label: 'Get Started',
                        onPressed: _completeOnboarding,
                        icon: Icons.check,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final String icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final Color iconBackgroundColor;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.iconBackgroundColor,
  });
}

class _OnboardingPageWidget extends StatelessWidget {
  final _OnboardingPage page;
  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Premium Icon Container
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: page.gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: page.iconBackgroundColor.withOpacity(0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: page.iconBackgroundColor.withOpacity(0.2),
                  blurRadius: 64,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            child: Center(
              child: Text(
                page.icon,
                style: const TextStyle(fontSize: 64),
              ),
            ),
          ),
          const SizedBox(height: 48),
          
          // Title
          Text(
            page.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito',
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          // Subtitle
          Text(
            page.subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 17,
              height: 1.5,
              fontFamily: 'Nunito',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
