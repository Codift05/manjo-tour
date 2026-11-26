import 'package:flutter/material.dart';

/// Purposeful motion constants inspired by Emil Kowalski's design engineering principles:
/// snappy ease-out curves under 300ms, never scale(0), and full reduced-motion support.
class AppMotion {
  AppMotion._();

  static const Duration press = Duration(milliseconds: 140);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration sheet = Duration(milliseconds: 280);

  /// Strong ease-out curve for crisp UI feedback (cubic-bezier(0.23, 1, 0.32, 1)).
  static const Curve easeOutStrong = Cubic(0.23, 1.0, 0.32, 1.0);

  /// Drawer / sheet curve for smooth organic deceleration (cubic-bezier(0.32, 0.72, 0, 1)).
  static const Curve drawer = Cubic(0.32, 0.72, 0.0, 1.0);

  static bool reduceMotion(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  static Duration effective(BuildContext context, Duration normal) {
    return reduceMotion(context) ? Duration.zero : normal;
  }
}
