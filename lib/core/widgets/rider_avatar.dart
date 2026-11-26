import 'package:flutter/material.dart';

/// Lightweight circular Rider Avatar widget backed by memory-capped `.webp` assets
/// sliced from `Avatar.png`, with clean initials fallback when no image path is provided.
class RiderAvatar extends StatelessWidget {
  const RiderAvatar({
    super.key,
    required this.size,
    required this.initials,
    required this.fallbackColor,
    this.assetPath,
    this.ringColor,
    this.ringWidth = 0,
    this.shadow,
    this.semanticLabel,
  });

  final double size;
  final String initials;
  final Color fallbackColor;
  final String? assetPath;
  final Color? ringColor;
  final double ringWidth;
  final List<BoxShadow>? shadow;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 2.5);
    final decodePx = (size * dpr).round().clamp(64, 256);

    Widget inner;
    if (assetPath != null && assetPath!.isNotEmpty) {
      inner = ClipOval(
        child: Image.asset(
          assetPath!,
          width: size,
          height: size,
          cacheWidth: decodePx,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          semanticLabel: semanticLabel,
          excludeFromSemantics: semanticLabel == null,
        ),
      );
    } else {
      inner = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fallbackColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.34,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    if (ringWidth > 0 || (shadow != null && shadow!.isNotEmpty)) {
      return Container(
        width: size,
        height: size,
        padding: ringWidth > 0 ? EdgeInsets.all(ringWidth) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: ringColor ?? Colors.white,
          shape: BoxShape.circle,
          boxShadow: shadow,
        ),
        child: inner,
      );
    }

    return SizedBox(width: size, height: size, child: inner);
  }
}
