import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/models/achievement.dart';

/// Celebration overlay that shows when a milestone is reached
class CelebrationOverlay extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback onDismiss;

  const CelebrationOverlay({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _scaleController.forward();
    _confettiController.forward();

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _scaleController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.7),
      child: GestureDetector(
        onTap: _dismiss,
        child: Stack(
          children: [
            // Confetti animation
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ConfettiPainter(_confettiController.value),
                  );
                },
              ),
            ),

            // Achievement card
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.cardBackground,
                        AppColors.darkCardBackground,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.brandPrimary.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandPrimary.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Emoji
                      Text(
                        widget.achievement.type.emoji,
                        style: const TextStyle(fontSize: 64),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        widget.achievement.type.title,
                        style: AppTextStyles.title2.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Description
                      Text(
                        widget.achievement.type.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontFamily: 'Nunito',
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Progress value if available
                      if (widget.achievement.progressValue != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppGradients.brand,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getProgressText(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Dismiss button
                      TextButton(
                        onPressed: _dismiss,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Awesome!',
                          style: TextStyle(
                            color: AppColors.brandPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getProgressText() {
    final value = widget.achievement.progressValue!;
    final type = widget.achievement.type;

    if (type.id.contains('weight_progress')) {
      return '${value.toStringAsFixed(0)}% Complete';
    } else if (type.id.contains('streak')) {
      return '${value.toInt()} Day Streak';
    } else if (type.id.contains('photos')) {
      return '${value.toInt()} Photos';
    } else if (type.id.contains('entries')) {
      return '${value.toInt()} Entries';
    }
    return '';
  }
}

/// Custom painter for confetti animation
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final math.Random _random = math.Random(42); // Fixed seed for consistent animation

  _ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final confettiCount = 60;
    final colors = [
      AppColors.brandPrimary,
      AppColors.brandSecondary,
      Colors.yellow,
      Colors.pink,
      Colors.purple,
      Colors.cyan,
    ];

    for (int i = 0; i < confettiCount; i++) {
      final randomSeed = _random.nextDouble();
      final color = colors[i % colors.length];

      // Calculate position
      final startX = size.width * (i / confettiCount);
      final endX = startX + (_random.nextDouble() - 0.5) * 100;
      final endY = size.height * progress * (1 + randomSeed * 0.5);

      final x = startX + (endX - startX) * progress;
      final y = endY;

      // Rotation
      final rotation = progress * math.pi * 4 * (_random.nextDouble() - 0.5);

      // Opacity fade out towards the end
      final opacity = (1 - progress).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      // Random shapes (rectangle or circle)
      if (i % 2 == 0) {
        canvas.drawRect(
          const Rect.fromLTWH(-4, -8, 8, 16),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, 5, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}
