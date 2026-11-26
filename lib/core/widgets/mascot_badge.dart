import 'package:flutter/material.dart';
import '../theme/app_motion.dart';

enum MascotPose {
  hero,
  ride,
  empty,
  alert,
  ptt,
  celebrate,
}

/// Renders our lightweight WebP Panda Rider Mascot (static or animated WebP)
/// extracted from `Maskot Panda.png`, wrapped in a [RepaintBoundary] with
/// memory-capped decoding and automatic reduced-motion fallback.
class MascotArt extends StatelessWidget {
  const MascotArt({
    super.key,
    required this.pose,
    this.size = 96,
    this.animated = true,
    this.semanticLabel,
  });

  final MascotPose pose;
  final double size;
  final bool animated;
  final String? semanticLabel;

  String get _staticPath => switch (pose) {
        MascotPose.hero => 'assets/images/panda_hero.webp',
        MascotPose.ride => 'assets/images/panda_ride.webp',
        MascotPose.empty => 'assets/images/panda_empty.webp',
        MascotPose.alert => 'assets/images/panda_alert.webp',
        MascotPose.ptt => 'assets/images/panda_ptt.webp',
        MascotPose.celebrate => 'assets/images/panda_celebrate.webp',
      };

  String get _animatedPath => switch (pose) {
        MascotPose.hero => 'assets/animations/panda_hero_anim.webp',
        MascotPose.ride => 'assets/animations/panda_ride_anim.webp',
        MascotPose.empty => 'assets/animations/panda_empty_anim.webp',
        MascotPose.alert => 'assets/animations/panda_alert_anim.webp',
        MascotPose.ptt => 'assets/animations/panda_ptt_anim.webp',
        MascotPose.celebrate => 'assets/animations/panda_celebrate_anim.webp',
      };

  @override
  Widget build(BuildContext context) {
    final useAnim = animated && !AppMotion.reduceMotion(context);
    final dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 2.5);
    final decodePx = (size * dpr).round().clamp(96, 420);

    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          useAnim ? _animatedPath : _staticPath,
          width: size,
          height: size,
          cacheWidth: useAnim ? null : decodePx,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          semanticLabel: semanticLabel ?? 'Maskot Panda Konvoi',
          excludeFromSemantics: semanticLabel == null,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
