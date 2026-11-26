import 'package:flutter/material.dart';

/// Consistent spacing and deliberate radius hierarchy (R-11).
/// Radii differentiate roles: cards (24), primary actions (18), inputs (16), badges (12), filter pills (999).
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  // Radius hierarchy
  static const double radiusBadge = 12;
  static const double radiusInput = 16;
  static const double radiusButton = 18;
  static const double radiusCard = 24;
  static const double radiusSheet = 28;
  static const double radiusPill = 999;

  // Ergonomic target sizes
  static const double minTapTarget = 48;
  static const double ridingControlHeight = 60;
  static const double ridingPrimaryHeight = 64;

  // Bottom navigation reserved inset so floating navbar never overlaps last content item
  static const double floatingNavClearance = 104;

  static const BorderRadius cardBorderRadius =
      BorderRadius.all(Radius.circular(radiusCard));
  static const BorderRadius buttonBorderRadius =
      BorderRadius.all(Radius.circular(radiusButton));
  static const BorderRadius inputBorderRadius =
      BorderRadius.all(Radius.circular(radiusInput));
  static const BorderRadius badgeBorderRadius =
      BorderRadius.all(Radius.circular(radiusBadge));
}
