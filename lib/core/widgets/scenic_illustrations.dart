import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ScenicVariant {
  mountain,
  coast,
  pineCamp,
  sunsetPass,
  profileHorizon,
  leaderboardSunset,
}

/// Renders our optimized WebP flat-vector Indonesian touring landscape illustrations
/// extracted from `Card.png` and `Bagian Profile.png` with memory-efficient decode capping.
class ScenicIllustration extends StatelessWidget {
  const ScenicIllustration({
    super.key,
    required this.variant,
    this.width,
    this.height = 160,
    this.borderRadius,
  });

  final ScenicVariant variant;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  String get _assetPath => switch (variant) {
        ScenicVariant.mountain => 'assets/images/route_tangkuban.webp',
        ScenicVariant.coast => 'assets/images/route_sawarna.webp',
        ScenicVariant.pineCamp => 'assets/images/route_rancaupas.webp',
        ScenicVariant.sunsetPass => 'assets/images/route_dieng.webp',
        ScenicVariant.profileHorizon => 'assets/images/profile_horizon.webp',
        ScenicVariant.leaderboardSunset =>
          'assets/images/leaderboard_sunset.webp',
      };

  Color get _placeholderColor => switch (variant) {
        ScenicVariant.mountain => AppColors.softMint,
        ScenicVariant.coast => const Color(0xFFE0F7FA),
        ScenicVariant.pineCamp => const Color(0xFFDCFCE7),
        ScenicVariant.sunsetPass => AppColors.warmCream,
        ScenicVariant.profileHorizon => const Color(0xFFC9DFB2),
        ScenicVariant.leaderboardSunset => const Color(0xFFFDE0B0),
      };

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 2.0);
    final targetHeightPx = (height * dpr).round().clamp(120, 560);
    final int? targetWidthPx =
        width != null ? (width! * dpr).round().clamp(120, 560) : null;

    Widget image = Container(
      width: width ?? double.infinity,
      height: height,
      color: _placeholderColor,
      child: Image.asset(
        _assetPath,
        width: width ?? double.infinity,
        height: height,
        cacheWidth: targetWidthPx,
        cacheHeight: targetHeightPx,
        fit: BoxFit.cover,
        alignment: variant == ScenicVariant.leaderboardSunset
            ? Alignment.bottomCenter
            : Alignment.center,
        gaplessPlayback: true,
        filterQuality: FilterQuality.low,
      ),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return ExcludeSemantics(child: image);
  }
}
