import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'mascot_badge.dart';
import 'organic_card.dart';
import 'tactile_button.dart';

/// Informative Empty State with animated Panda holding a touring map (R-27).
class KonvoiEmptyState extends StatelessWidget {
  const KonvoiEmptyState({
    super.key,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
    this.pose = MascotPose.empty,
  });

  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;
  final MascotPose pose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return OrganicCard(
      tone: OrganicCardTone.flat,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MascotArt(pose: pose, size: 108, semanticLabel: title),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          TactileButton(
            label: actionLabel,
            onPressed: onAction,
            variant: TactileButtonVariant.primary,
          ),
        ],
      ),
    );
  }
}

/// Perceivable Loading State featuring animated Panda riding motorbike WebP (R-27).
class KonvoiLoadingState extends StatelessWidget {
  const KonvoiLoadingState({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      liveRegion: true,
      label: message,
      child: OrganicCard(
        tone: OrganicCardTone.flat,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const MascotArt(
              pose: MascotPose.ride,
              size: 112,
              semanticLabel: 'Maskot Panda sedang memuat data',
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  backgroundColor: tokens.surfaceMuted,
                  color: tokens.primaryAction,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Actionable Error State with animated Panda warning flag (R-27).
class KonvoiErrorState extends StatelessWidget {
  const KonvoiErrorState({
    super.key,
    required this.title,
    required this.reason,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String reason;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return OrganicCard(
      tone: OrganicCardTone.warm,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const MascotArt(
            pose: MascotPose.alert,
            size: 104,
            semanticLabel: 'Peringatan gangguan',
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            reason,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          TactileButton(
            label: retryLabel,
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
            variant: TactileButtonVariant.secondary,
          ),
        ],
      ),
    );
  }
}
