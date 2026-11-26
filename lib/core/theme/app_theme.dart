import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    // Rounded, warm, friendly Nunito matching Refrensi 4.png & PRD Section 3C.
    final base = GoogleFonts.nunitoTextTheme();
    const tabular = <FontFeature>[FontFeature.tabularFigures()];
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.12,
        color: primary,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 23,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.2,
        color: primary,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 18.5,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.26,
        color: primary,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.28,
        color: primary,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.32,
        fontFeatures: tabular,
        color: primary,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        height: 1.32,
        fontFeatures: tabular,
        color: primary,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.48,
        color: primary,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: secondary,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        height: 1.38,
        fontFeatures: tabular,
        color: secondary,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: primary,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        fontFeatures: tabular,
        color: secondary,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        fontFeatures: tabular,
        color: secondary,
      ),
    );
  }

  static ThemeData light() {
    const tokens = KonvoiColorTokens.light;
    final textTheme = _buildTextTheme(
      tokens.textPrimary,
      tokens.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: tokens.canvas,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brandGreenDeep,
        onPrimary: Colors.white,
        secondary: AppColors.accentOrangeDeep,
        onSecondary: Colors.white,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        error: AppColors.dangerRed,
        onError: Colors.white,
        outline: AppColors.softBorder,
      ),
      textTheme: textTheme,
      extensions: const <ThemeExtension<dynamic>>[tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.canvas,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMutedLight),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.inputBorderRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputBorderRadius,
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputBorderRadius,
          borderSide: const BorderSide(
            color: Color(0xFFC24515),
            width: 1.5,
          ),
        ),
      ),
      dividerColor: tokens.border,
      focusColor: AppColors.brandGreenDeep.withValues(alpha: 0.16),
    );
  }

  static ThemeData riding() {
    const tokens = KonvoiColorTokens.riding;
    final textTheme = _buildTextTheme(
      tokens.textPrimary,
      tokens.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: tokens.canvas,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brandMintBright,
        onPrimary: AppColors.backgroundRiding,
        secondary: AppColors.ridingAccentOrange,
        onSecondary: AppColors.backgroundRiding,
        surface: AppColors.surfaceRiding,
        onSurface: AppColors.textPrimaryRiding,
        error: Color(0xFFF87171),
        onError: AppColors.backgroundRiding,
        outline: AppColors.borderRiding,
      ),
      textTheme: textTheme,
      extensions: const <ThemeExtension<dynamic>>[tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.canvas,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: textTheme.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.inputBorderRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputBorderRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputBorderRadius,
          borderSide: const BorderSide(
            color: AppColors.brandMintBright,
            width: 2,
          ),
        ),
      ),
      dividerColor: tokens.border,
      focusColor: AppColors.brandMintBright.withValues(alpha: 0.2),
    );
  }
}
