import 'package:flutter/material.dart';

// ─────────────────────────────────────────
// BRAND COLORS  (Dark-mode first design)
// ─────────────────────────────────────────
class AppColors {
  // Brand
  static const brandPrimary   = Color(0xFFFF6B35); // coral-orange
  static const brandSecondary = Color(0xFF1B98E0); // professional blue
  static const brandAccent    = Color(0xFFFF9F1C); // warm gold

  // Gradient stops
  static const gradientStart  = Color(0xFFFF6B35);
  static const gradientEnd    = Color(0xFFFF9F1C);
  static const blueGradStart  = Color(0xFF1B98E0);
  static const blueGradEnd    = Color(0xFF0066CC);

  // Backgrounds
  static const appBackground         = Color(0xFF000000); // true black
  static const cardBackground        = Color(0xFF1C1C1E);
  static const darkCardBackground    = Color(0xFF2C2C2E);
  static const secondaryCardBg       = Color(0xFF1C1C1E);

  // Text
  static const textPrimary    = Color(0xFFFFFFFF);
  static const textSecondary  = Color(0xFFA0A0A0);
  static const textTertiary   = Color(0xFF707070);

  // Semantic
  static const successGreen   = Color(0xFF10B981);
  static const warningOrange  = Color(0xFFF59E0B);
  static const errorRed       = Color(0xFFEF4444);
  static const infoBlue       = Color(0xFF3B82F6);
}

// ─────────────────────────────────────────
// GRADIENTS
// ─────────────────────────────────────────
class AppGradients {
  static const brand = LinearGradient(
    colors: [AppColors.gradientStart, AppColors.gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const brandVertical = LinearGradient(
    colors: [AppColors.gradientStart, AppColors.gradientEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const blue = LinearGradient(
    colors: [AppColors.blueGradStart, AppColors.blueGradEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const subtle = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF1C1C1E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const glass = LinearGradient(
    colors: [Color(0x26FFFFFF), Color(0x0DFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const success = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF8BC34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─────────────────────────────────────────
// TYPOGRAPHY
// ─────────────────────────────────────────
class AppTextStyles {
  static const String _font = 'Nunito';

  static const largeTitle  = TextStyle(fontSize: 34, fontWeight: FontWeight.w800, fontFamily: _font, color: AppColors.textPrimary);
  static const title1      = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, fontFamily: _font, color: AppColors.textPrimary);
  static const title2      = TextStyle(fontSize: 22, fontWeight: FontWeight.w600, fontFamily: _font, color: AppColors.textPrimary);
  static const title3      = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, fontFamily: _font, color: AppColors.textPrimary);
  static const body        = TextStyle(fontSize: 17, fontWeight: FontWeight.w400, fontFamily: _font, color: AppColors.textPrimary);
  static const bodyBold    = TextStyle(fontSize: 17, fontWeight: FontWeight.w600, fontFamily: _font, color: AppColors.textPrimary);
  static const callout     = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, fontFamily: _font, color: AppColors.textPrimary);
  static const subheadline = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, fontFamily: _font, color: AppColors.textSecondary);
  static const footnote    = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, fontFamily: _font, color: AppColors.textSecondary);
  static const caption1    = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, fontFamily: _font, color: AppColors.textSecondary);
  static const caption2    = TextStyle(fontSize: 11, fontWeight: FontWeight.w400, fontFamily: _font, color: AppColors.textTertiary);
  static const navTitle    = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: _font, color: AppColors.textPrimary);
  static const cardTitle   = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: _font, color: AppColors.textPrimary);
  static const numberLarge = TextStyle(fontSize: 32, fontWeight: FontWeight.w700, fontFamily: _font, color: AppColors.textPrimary);
  static const numberMedium= TextStyle(fontSize: 24, fontWeight: FontWeight.w600, fontFamily: _font, color: AppColors.textPrimary);
}

// ─────────────────────────────────────────
// SHADOWS & EFFECTS
// ─────────────────────────────────────────
class AppShadows {
  static const small = [
    BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  static const medium = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 4)),
  ];

  static const large = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 16, offset: Offset(0, 8)),
  ];

  static const extraLarge = [
    BoxShadow(color: Color(0x26000000), blurRadius: 24, offset: Offset(0, 12)),
  ];

  // Premium colored glows
  static const primaryGlow = [
    BoxShadow(color: Color(0x4DFF6B35), blurRadius: 20, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x26FF6B35), blurRadius: 40, offset: Offset(0, 20)),
  ];

  static const secondaryGlow = [
    BoxShadow(color: Color(0x4D1B98E0), blurRadius: 20, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x261B98E0), blurRadius: 40, offset: Offset(0, 20)),
  ];

  static const accentGlow = [
    BoxShadow(color: Color(0x4DFF9F1C), blurRadius: 20, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x26FF9F1C), blurRadius: 40, offset: Offset(0, 20)),
  ];

  // Card shadows (optimized for dark mode)
  static const cardShadow = [
    BoxShadow(color: Color(0x0DFFFFFF), blurRadius: 10, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x05FFFFFF), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const cardElevated = [
    BoxShadow(color: Color(0x14FFFFFF), blurRadius: 16, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0AFFFFFF), blurRadius: 4, offset: Offset(0, 2)),
  ];
}

// ─────────────────────────────────────────
// SPACING
// ─────────────────────────────────────────
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

// ─────────────────────────────────────────
// PREMIUM VIEW EXTENSIONS
// ─────────────────────────────────────────
extension PremiumWidgetExtensions on Widget {
  // Premium card with gradient overlay and stroke
  Widget premiumCard({
    EdgeInsets padding = const EdgeInsets.all(16),
    double borderRadius = 20,
    bool withGradientOverlay = true,
    bool withStroke = true,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: withGradientOverlay
            ? const LinearGradient(
                colors: [Color(0x26FF6B35), Color(0x1AFF9F1C), Color(0xFF1C1C1E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: withGradientOverlay ? null : AppColors.cardBackground,
        boxShadow: AppShadows.cardShadow,
        border: withStroke
            ? Border.all(
                width: 1,
                color: const Color(0x4DFF6B35),
              )
            : null,
      ),
      child: this,
    );
  }

  // Glass morphism effect
  Widget glassMorphism({double borderRadius = 20}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const LinearGradient(
          colors: [Color(0x26FFFFFF), Color(0x0DFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0x33FFFFFF), width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x0DFFFFFF), blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: this,
    );
  }

  // Primary button style
  Widget primaryButton({
    VoidCallback? onTap,
    double borderRadius = 16,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppGradients.brand,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: AppShadows.primaryGlow,
        ),
        child: Center(
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              fontFamily: 'Nunito',
            ),
            child: this,
          ),
        ),
      ),
    );
  }

  // Secondary button style
  Widget secondaryButton({
    VoidCallback? onTap,
    double borderRadius = 16,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: const Color(0x4DFF6B35), width: 1),
        ),
        child: Center(
          child: DefaultTextStyle(
            style: const TextStyle(
              color: AppColors.brandPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              fontFamily: 'Nunito',
            ),
            child: this,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// CORNER RADIUS
// ─────────────────────────────────────────
class AppRadius {
  static const double small      = 8;
  static const double medium     = 12;
  static const double large      = 16;
  static const double extraLarge = 24;
  static const double circle     = 1000;
}

// ─────────────────────────────────────────
// THEME DATA
// ─────────────────────────────────────────
class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Nunito',
      scaffoldBackgroundColor: AppColors.appBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brandPrimary,
        secondary: AppColors.brandSecondary,
        surface: AppColors.cardBackground,
        error: AppColors.errorRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.appBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.navTitle,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.brandPrimary,
        unselectedLabelColor: Colors.grey,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: AppTextStyles.bodyBold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.brandPrimary),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      dividerColor: Colors.white.withOpacity(0.08),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      textTheme: const TextTheme(
        displayLarge:  AppTextStyles.largeTitle,
        displayMedium: AppTextStyles.title1,
        displaySmall:  AppTextStyles.title2,
        headlineMedium:AppTextStyles.title3,
        bodyLarge:     AppTextStyles.body,
        bodyMedium:    AppTextStyles.callout,
        bodySmall:     AppTextStyles.footnote,
        labelSmall:    AppTextStyles.caption1,
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }
}
