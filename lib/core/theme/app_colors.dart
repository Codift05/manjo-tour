import 'package:flutter/material.dart';

/// Warm Organic Adventure palette calibrated directly from Refrensi 4.png + PRD brand tokens.
/// Every text/surface pair is verified >= 4.5:1 WCAG AA.
class AppColors {
  AppColors._();

  // Primary Brand: Organic Adventure Green
  static const Color brandGreen = Color(0xFF22A861);
  static const Color brandMintBright = Color(0xFF4ADE80);
  static const Color brandGreenDeep = Color(0xFF18794B); // White text 5.42:1
  static const Color brandGreenForest = Color(0xFF134E32);

  // Warm Earthy Accent (Refrensi 4 Discover & Leaderboard)
  static const Color accentOrange = Color(0xFFF4933E);
  static const Color accentAmber = Color(0xFF9A5B1F); // 5.40:1 on #FFFFFF
  static const Color accentOrangeDeep = Color(0xFFC2410C); // White text 5.18:1
  static const Color accentEspresso = Color(0xFF2C1F1A); // 15.93:1 on #FFFFFF
  static const Color ribbonBronze = Color(0xFF8C5428); // White text 6.15:1

  // Organic Pastel Card Tints (Refrensi 4 signature cards)
  static const Color cardSage = Color(0xFFB5D592);
  static const Color cardApricot = Color(0xFFF7CE92);
  static const Color cardCoast = Color(0xFFBCE4F2);
  static const Color cardPine = Color(0xFFD3EAD9);

  // Soft Surface Tints
  static const Color softMint = Color(0xFFEAF5EE);
  static const Color softMintInk = Color(0xFF134E32);
  static const Color warmCream = Color(0xFFFEF3DC);
  static const Color warmCreamInk = Color(0xFF8C4612);
  static const Color neutralSurface = Color(0xFFF5F3F0);
  static const Color softBorder = Color(0xFFEBE5DD);

  // Light Mode Canvas & Text Hierarchy (soft warm bone canvas so borderless #FFFFFF cards stand out naturally)
  static const Color backgroundLight = Color(0xFFF7F6F2);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF2C1F1A); // 14.8:1 on #F7F6F2
  static const Color textSecondaryLight = Color(0xFF6B5F57); // 5.7:1 on #F7F6F2
  static const Color textMutedLight = Color(0xFF746860);

  // High-Contrast Riding Mode (Night / Active Navigation) - clean tonal elevation, zero wireframe borders
  static const Color backgroundRiding = Color(0xFF0B1120);
  static const Color surfaceRiding = Color(0xFF182235);
  static const Color surfaceElevatedRiding = Color(0xFF233047);
  static const Color borderRiding = Color(0xFF2B3B54);
  static const Color textPrimaryRiding = Color(0xFFF8FAFC); // 17.8:1 on #0B1120
  static const Color textSecondaryRiding = Color(0xFFCBD5E1); // 12.6:1 on #0B1120
  static const Color ridingAccentOrange = Color(0xFFFB923C); // 8.2:1 on #0B1120

  // Safety / Emergency Signals
  static const Color dangerRed = Color(0xFFB91C1C); // White text 6.47:1
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color dangerInk = Color(0xFF991B1B);
}

@immutable
class KonvoiColorTokens extends ThemeExtension<KonvoiColorTokens> {
  const KonvoiColorTokens({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceMint,
    required this.surfaceMintInk,
    required this.surfaceWarm,
    required this.surfaceWarmInk,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryAction,
    required this.onPrimaryAction,
    required this.secondaryAccent,
    required this.onSecondaryAccent,
    required this.shadowColor,
    required this.isRidingMode,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceMint;
  final Color surfaceMintInk;
  final Color surfaceWarm;
  final Color surfaceWarmInk;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color primaryAction;
  final Color onPrimaryAction;
  final Color secondaryAccent;
  final Color onSecondaryAccent;
  final Color shadowColor;
  final bool isRidingMode;

  static const KonvoiColorTokens light = KonvoiColorTokens(
    canvas: AppColors.backgroundLight,
    surface: AppColors.surfaceLight,
    surfaceMuted: AppColors.neutralSurface,
    surfaceMint: AppColors.softMint,
    surfaceMintInk: AppColors.softMintInk,
    surfaceWarm: AppColors.warmCream,
    surfaceWarmInk: AppColors.warmCreamInk,
    border: AppColors.softBorder,
    textPrimary: AppColors.textPrimaryLight,
    textSecondary: AppColors.textSecondaryLight,
    // Deep warm espresso button matching Refrensi 4 ("Let's Go" & active nav bubble)
    primaryAction: Color(0xFF2E1F19),
    onPrimaryAction: Colors.white,
    secondaryAccent: AppColors.accentOrange,
    onSecondaryAccent: AppColors.accentEspresso,
    shadowColor: Color(0x0D2C1F1A),
    isRidingMode: false,
  );

  static const KonvoiColorTokens riding = KonvoiColorTokens(
    canvas: AppColors.backgroundRiding,
    surface: AppColors.surfaceRiding,
    surfaceMuted: AppColors.surfaceElevatedRiding,
    surfaceMint: Color(0xFF133A2C),
    surfaceMintInk: AppColors.brandMintBright,
    surfaceWarm: Color(0xFF42230E),
    surfaceWarmInk: AppColors.ridingAccentOrange,
    border: AppColors.borderRiding,
    textPrimary: AppColors.textPrimaryRiding,
    textSecondary: AppColors.textSecondaryRiding,
    primaryAction: AppColors.brandMintBright,
    onPrimaryAction: AppColors.backgroundRiding,
    secondaryAccent: AppColors.ridingAccentOrange,
    onSecondaryAccent: AppColors.backgroundRiding,
    shadowColor: Color(0x38000000),
    isRidingMode: true,
  );

  @override
  KonvoiColorTokens copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceMint,
    Color? surfaceMintInk,
    Color? surfaceWarm,
    Color? surfaceWarmInk,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? primaryAction,
    Color? onPrimaryAction,
    Color? secondaryAccent,
    Color? onSecondaryAccent,
    Color? shadowColor,
    bool? isRidingMode,
  }) {
    return KonvoiColorTokens(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceMint: surfaceMint ?? this.surfaceMint,
      surfaceMintInk: surfaceMintInk ?? this.surfaceMintInk,
      surfaceWarm: surfaceWarm ?? this.surfaceWarm,
      surfaceWarmInk: surfaceWarmInk ?? this.surfaceWarmInk,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      primaryAction: primaryAction ?? this.primaryAction,
      onPrimaryAction: onPrimaryAction ?? this.onPrimaryAction,
      secondaryAccent: secondaryAccent ?? this.secondaryAccent,
      onSecondaryAccent: onSecondaryAccent ?? this.onSecondaryAccent,
      shadowColor: shadowColor ?? this.shadowColor,
      isRidingMode: isRidingMode ?? this.isRidingMode,
    );
  }

  @override
  KonvoiColorTokens lerp(ThemeExtension<KonvoiColorTokens>? other, double t) {
    if (other is! KonvoiColorTokens) return this;
    return KonvoiColorTokens(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceMint: Color.lerp(surfaceMint, other.surfaceMint, t)!,
      surfaceMintInk: Color.lerp(surfaceMintInk, other.surfaceMintInk, t)!,
      surfaceWarm: Color.lerp(surfaceWarm, other.surfaceWarm, t)!,
      surfaceWarmInk: Color.lerp(surfaceWarmInk, other.surfaceWarmInk, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      primaryAction: Color.lerp(primaryAction, other.primaryAction, t)!,
      onPrimaryAction: Color.lerp(onPrimaryAction, other.onPrimaryAction, t)!,
      secondaryAccent: Color.lerp(secondaryAccent, other.secondaryAccent, t)!,
      onSecondaryAccent:
          Color.lerp(onSecondaryAccent, other.onSecondaryAccent, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      isRidingMode: t >= 0.5 ? other.isRidingMode : isRidingMode,
    );
  }
}

extension KonvoiThemeLookup on BuildContext {
  KonvoiColorTokens get tokens =>
      Theme.of(this).extension<KonvoiColorTokens>() ?? KonvoiColorTokens.light;
}
