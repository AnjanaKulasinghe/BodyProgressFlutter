import 'package:flutter/material.dart';
import 'package:body_progress/core/design_system.dart';

// ═════════════════════════════════════════════════════════════════
// PREMIUM CARD WIDGET
// ═════════════════════════════════════════════════════════════════
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final List<Color>? gradientColors;
  final bool withStroke;
  final VoidCallback? onTap;

  const PremiumCard({
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.gradientColors,
    this.withStroke = true,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradientColors != null
            ? LinearGradient(
                colors: [
                  gradientColors![0].withOpacity(0.15),
                  gradientColors!.length > 1
                      ? gradientColors![1].withOpacity(0.05)
                      : gradientColors![0].withOpacity(0.05),
                  AppColors.cardBackground,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: gradientColors == null ? AppColors.cardBackground : null,
        border: withStroke
            ? Border.all(
                width: 1,
                color: gradientColors != null
                    ? gradientColors![0].withOpacity(0.3)
                    : AppColors.brandPrimary.withOpacity(0.3),
              )
            : null,
        boxShadow: AppShadows.cardShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}

// ═════════════════════════════════════════════════════════════════
// PREMIUM GRADIENT ICON
// ═════════════════════════════════════════════════════════════════
class PremiumGradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final List<Color> gradientColors;
  final bool withShadow;

  const PremiumGradientIcon({
    required this.icon,
    this.size = 48,
    this.gradientColors = const [Color(0xFFFF6B35), Color(0xFFFF9F1C)],
    this.withShadow = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// PREMIUM BADGE
// ═════════════════════════════════════════════════════════════════
class PremiumBadge extends StatelessWidget {
  final String text;
  final List<Color>? gradientColors;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsets? padding;

  const PremiumBadge({
    required this.text,
    this.gradientColors,
    this.backgroundColor,
    this.textColor,
    this.padding,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: gradientColors != null
            ? LinearGradient(
                colors: gradientColors!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: backgroundColor ?? AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: gradientColors != null
            ? [
                BoxShadow(
                  color: gradientColors![0].withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'Nunito',
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// PREMIUM SECTION HEADER
// ═════════════════════════════════════════════════════════════════
class PremiumSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onActionTap;
  final String? actionText;
  final IconData? actionIcon;

  const PremiumSectionHeader({
    required this.title,
    this.subtitle,
    this.onActionTap,
    this.actionText,
    this.actionIcon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onActionTap != null)
            GestureDetector(
              onTap: onActionTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionText ?? 'View All',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    if (actionIcon != null) ...[
                      const SizedBox(width: 4),
                      Icon(actionIcon, color: Colors.white, size: 16),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// PREMIUM EMPTY STATE
// ═════════════════════════════════════════════════════════════════
class PremiumEmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonTap;

  const PremiumEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onButtonTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                shape: BoxShape.circle,
                boxShadow: AppShadows.primaryGlow,
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 56),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'Nunito',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontFamily: 'Nunito',
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonTap != null) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onButtonTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppGradients.brand,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppShadows.primaryGlow,
                  ),
                  child: Text(
                    buttonText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// PREMIUM STAT DISPLAY WIDGET
// ═════════════════════════════════════════════════════════════════
class PremiumStatDisplay extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final List<Color> gradientColors;
  final String? trend;
  final bool isPositive;

  const PremiumStatDisplay({
    required this.label,
    required this.value,
    this.unit,
    required this.icon,
    this.gradientColors = const [Color(0xFFFF6B35), Color(0xFFFF9F1C)],
    this.trend,
    this.isPositive = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      gradientColors: gradientColors,
      child: Row(
        children: [
          PremiumGradientIcon(
            icon: icon,
            size: 48,
            gradientColors: gradientColors,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    if (unit != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        unit!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (trend != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isPositive
                    ? AppColors.successGreen.withOpacity(0.2)
                    : AppColors.errorRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isPositive ? AppColors.successGreen : AppColors.errorRed,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trend!,
                    style: TextStyle(
                      color: isPositive ? AppColors.successGreen : AppColors.errorRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

// ═════════════════════════════════════════════════════════════════
// PREMIUM AVATAR WITH RING
// ═════════════════════════════════════════════════════════════════
class PremiumAvatar extends StatelessWidget {
  final String text;
  final double size;
  final VoidCallback? onTap;
  final String? imageUrl;

  const PremiumAvatar({
    required this.text,
    this.size = 74,
    this.onTap,
    this.imageUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.brand,
        boxShadow: AppShadows.primaryGlow,
      ),
      child: Container(
        margin: EdgeInsets.all(size * 0.04),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.darkCardBackground,
        ),
        child: Container(
          margin: EdgeInsets.all(size * 0.027),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: imageUrl == null ? AppGradients.brand : null,
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageUrl == null
              ? Center(
                  child: Text(
                    text.isNotEmpty ? text[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.38,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito',
                    ),
                  ),
                )
              : null,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }

    return content;
  }
}
