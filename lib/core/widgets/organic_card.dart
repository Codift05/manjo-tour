import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum OrganicCardTone { elevated, flat, mint, warm, muted }

/// Ultra-clean flat-first organic card container:
/// relies on crisp 1px borders and subtle pastel tints rather than heavy AI drop shadows.
class OrganicCard extends StatelessWidget {
  const OrganicCard({
    super.key,
    required this.child,
    this.tone = OrganicCardTone.flat,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.borderRadius = AppSpacing.cardBorderRadius,
    this.onTap,
    this.semanticLabel,
    this.clipBehavior = Clip.none,
    this.borderColor,
  });

  final Widget child;
  final OrganicCardTone tone;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final Clip clipBehavior;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final Color bg = switch (tone) {
      OrganicCardTone.elevated => tokens.surface,
      OrganicCardTone.flat => tokens.surface,
      OrganicCardTone.mint => tokens.surfaceMint,
      OrganicCardTone.warm => tokens.surfaceWarm,
      OrganicCardTone.muted => tokens.surfaceMuted,
    };

    // Soft tonal surface separation with lightweight GPU blur radii.
    final List<BoxShadow>? shadows =
        (tone == OrganicCardTone.elevated || tone == OrganicCardTone.flat) &&
                !tokens.isRidingMode
            ? <BoxShadow>[
                BoxShadow(
                  color: tokens.shadowColor,
                  blurRadius: tone == OrganicCardTone.elevated ? 10 : 6,
                  offset: Offset(0, tone == OrganicCardTone.elevated ? 3 : 2),
                  spreadRadius: 0,
                ),
              ]
            : null;

    // Completely borderless across both Light and Dark Mode unless an explicit semantic alert color is passed.
    final Border? border = borderColor != null
        ? Border.all(color: borderColor!, width: 1.5)
        : null;

    Widget content = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: borderRadius,
        boxShadow: shadows,
        border: border,
      ),
      clipBehavior: clipBehavior,
      child: Material(
        type: MaterialType.transparency,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: borderRadius,
                splashColor: tokens.textPrimary.withValues(alpha: 0.06),
                highlightColor: tokens.textPrimary.withValues(alpha: 0.03),
                child: Padding(padding: padding, child: child),
              )
            : Padding(padding: padding, child: child),
      ),
    );

    if (semanticLabel != null) {
      content = Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: content,
      );
    }

    return content;
  }
}
