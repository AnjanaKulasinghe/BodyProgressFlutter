import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/core/router.dart';
import 'package:body_progress/providers/auth_provider.dart';
import 'package:body_progress/providers/app_init_provider.dart';

/// Premium animated splash / loading screen matching iOS design
class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _gradientController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _titleOffset;
  late Animation<double> _titleOpacity;
  late Animation<double> _rotation;
  late Animation<double> _pulse;

  double _loadingProgress = 0.0;
  int _currentStepIndex = 0;
  
  final List<String> _loadingSteps = [
    'Initializing app...',
    'Loading user data...',
    'Syncing data...',
    'Loading stats...',
    'Loading photos...',
    'Almost ready...'
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    _startLoading();
  }

  void _setupAnimations() {
    // Logo entrance animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // Title animation
    _titleOffset = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // Continuous rotation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _rotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(_rotationController);

    // Pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Gradient animation
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  void _startAnimations() {
    _logoController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  Future<void> _startLoading() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));

      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated || !authState.canProceed) {
        if (mounted) context.go(AppRoutes.auth);
        return;
      }

      // Step 1: Initialize - 10%
      _updateProgress(0.1, 0);
      await Future.delayed(const Duration(milliseconds: 400));

      // Step 2: User data - 25%
      _updateProgress(0.25, 1);
      await Future.delayed(const Duration(milliseconds: 400));

      // Step 3: Syncing - 45%
      _updateProgress(0.35, 2);
      await Future.delayed(const Duration(milliseconds: 300));
      _updateProgress(0.45, 2);
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 4: Loading stats - 60%
      _updateProgress(0.5, 3);
      
      // Initialize all data in parallel with timeout
      await ref.read(appInitProvider.notifier).initializeAppData().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Data loading timed out, proceeding anyway');
        },
      );
      
      _updateProgress(0.6, 3);
      await Future.delayed(const Duration(milliseconds: 400));

      // Step 5: Loading photos - 85%
      _updateProgress(0.7, 4);
      await Future.delayed(const Duration(milliseconds: 400));
      _updateProgress(0.85, 4);
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 6: Complete - 100%
      _updateProgress(1.0, 5);
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      print('Loading screen error: $e');
      if (mounted) context.go(AppRoutes.home);
    }
  }

  void _updateProgress(double progress, int stepIndex) {
    if (!mounted) return;
    setState(() {
      _loadingProgress = progress;
      _currentStepIndex = stepIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.lerp(
                      Alignment.topLeft,
                      Alignment.topRight,
                      _gradientController.value,
                    )!,
                    end: Alignment.lerp(
                      Alignment.bottomRight,
                      Alignment.bottomLeft,
                      _gradientController.value,
                    )!,
                    colors: const [
                      AppColors.brandPrimary,
                      AppColors.brandAccent,
                      AppColors.brandSecondary,
                      AppColors.brandPrimary,
                    ],
                  ),
                ),
              );
            },
          ),

          // Floating particles
          ...List.generate(15, (index) => _FloatingParticle(index: index)),

          // Main content
          AnimatedBuilder(
            animation: Listenable.merge([
              _logoOpacity,
              _logoScale,
              _titleOpacity,
              _titleOffset,
              _rotation,
              _pulse,
            ]),
            builder: (context, child) {
              return Column(
                children: [
                  const Spacer(),

                  // Premium animated logo
                  Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: _buildAnimatedLogo(),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Title with animation
                  Transform.translate(
                    offset: Offset(0, _titleOffset.value),
                    child: Opacity(
                      opacity: _titleOpacity.value,
                      child: _buildTitle(),
                    ),
                  ),

                  const Spacer(),

                  // Modern progress section
                  _buildProgressSection(),

                  const Spacer(),

                  // Company branding
                  _buildBranding(),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glowing rings
          ...List.generate(3, (i) {
            return Transform.scale(
              scale: _pulse.value + i * 0.05,
              child: Container(
                width: 140 + i * 20.0,
                height: 140 + i * 20.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3 - i * 0.1),
                    width: 2,
                  ),
                ),
              ),
            );
          }),

          // Rotating ring
          Transform.rotate(
            angle: _rotation.value,
            child: CustomPaint(
              size: const Size(140, 140),
              painter: _RotatingRingPainter(),
            ),
          ),

          // Inner glowing circle
          Transform.scale(
            scale: _pulse.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Icon with glow
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.fitness_center,
              size: 50,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'Body Progress',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontFamily: 'Nunito',
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Transform your journey',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
            fontFamily: 'Nunito',
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          // Progress bar with shimmer
          Container(
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.15),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Active progress
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: MediaQuery.of(context).size.width * 0.8 * _loadingProgress,
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Colors.white, Colors.white, Colors.white],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.7),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                  ),
                ),
                // Shimmer dot at the end
                if (_loadingProgress > 0 && _loadingProgress < 1)
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0.8 * _loadingProgress - 48,
                    top: -3,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Percentage and status
          Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '${(_loadingProgress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.3),
                      fontFamily: 'Nunito',
                    ),
                  ),
                  Text(
                    '${(_loadingProgress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: _pulse.value,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _loadingSteps[_currentStepIndex],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.95),
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBranding() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.auto_awesome,
          size: 12,
          color: Colors.white.withOpacity(0.7),
        ),
        const SizedBox(width: 6),
        Text(
          'Powered by Kounga Solutions',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.7),
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          Icons.auto_awesome,
          size: 12,
          color: Colors.white.withOpacity(0.7),
        ),
      ],
    );
  }
}

// Custom painter for rotating ring
class _RotatingRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.white,
          Colors.white.withOpacity(0.8),
          Colors.white.withOpacity(0.3),
          Colors.white,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.addArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      0,
      1.5 * math.pi,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Floating particle widget
class _FloatingParticle extends StatefulWidget {
  final int index;

  const _FloatingParticle({required this.index});

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _position;
  late Animation<double> _opacity;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000 + _random.nextInt(2000)),
    );

    final startX = _random.nextDouble();
    final startY = _random.nextDouble();
    final endX = startX + (_random.nextDouble() - 0.5) * 0.3;
    final endY = startY - 0.3 - _random.nextDouble() * 0.4;

    _position = Tween<Offset>(
      begin: Offset(startX, startY),
      end: Offset(endX, endY),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.0), weight: 1),
    ]).animate(_controller);

    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = [3.0, 4.0, 5.0, 6.0][widget.index % 4];
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: MediaQuery.of(context).size.width * _position.value.dx,
          top: MediaQuery.of(context).size.height * _position.value.dy,
          child: Opacity(
            opacity: _opacity.value,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
