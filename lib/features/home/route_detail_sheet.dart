import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/organic_card.dart';
import '../../core/widgets/scenic_illustrations.dart';
import '../../core/widgets/tactile_button.dart';
import '../../data/models/route_model.dart';
import '../../state/touring_controller.dart';

/// Full-featured Route Detail Screen inspired by Refrensi 1.png (left) & Refrensi 2.png (middle):
/// full-bleed flat landscape header, overlapping rounded sheet, weather & mini route preview,
/// checkpoints timeline, offline route download toggle, and sticky bottom riding CTA.
class RouteDetailScreen extends StatelessWidget {
  const RouteDetailScreen({
    super.key,
    required this.routeId,
  });

  final String routeId;

  @override
  Widget build(BuildContext context) {
    final controller = TouringScope.read(context);
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: controller.homeNotifier,
      builder: (context, _) {
        final route = controller.allRoutes.firstWhere(
          (r) => r.id == routeId,
          orElse: () => controller.activeRoute,
        );

        return Scaffold(
          backgroundColor: tokens.canvas,
          body: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Stack(
                  children: <Widget>[
                    // Full-bleed landscape melting seamlessly into canvas (no harsh sheet seam)
                    Stack(
                      children: <Widget>[
                        ScenicIllustration(
                          variant: route.scenicVariant,
                          height: 270,
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 96,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  tokens.canvas.withValues(alpha: 0.0),
                                  tokens.canvas,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Top floating controls over safe area
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            TactileIconButton(
                              icon: Icons.arrow_back_rounded,
                              tooltip: 'Kembali',
                              backgroundColor: tokens.surface,
                              foregroundColor: tokens.textPrimary,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            TactileIconButton(
                              icon: route.isBookmarked
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              tooltip: route.isBookmarked
                                  ? 'Hapus dari tersimpan'
                                  : 'Simpan rute',
                              backgroundColor: tokens.surface,
                              foregroundColor: route.isBookmarked
                                  ? AppColors.accentOrangeDeep
                                  : tokens.textPrimary,
                              onPressed: () =>
                                  controller.toggleRouteBookmark(route.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Clean seamless content start (no rounded card jump)
                    Container(
                      margin: const EdgeInsets.only(top: 232),
                      padding: const EdgeInsets.fromLTRB(
                        22,
                        8,
                        22,
                        AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      route.title,
                                      style: textTheme.headlineMedium,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: <Widget>[
                                        Icon(
                                          Icons.place_rounded,
                                          size: 16,
                                          color: tokens.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            route.region,
                                            style: textTheme.bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              // Clean editorial espresso metric pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: tokens.primaryAction,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  children: <Widget>[
                                    Text(
                                      '${route.distanceKm.toStringAsFixed(0)} km',
                                      style: textTheme.titleMedium?.copyWith(
                                        color: tokens.onPrimaryAction,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      route.formattedDuration,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: tokens.onPrimaryAction
                                            .withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(route.description, style: textTheme.bodyLarge),
                          const SizedBox(height: AppSpacing.lg),

                          // Side-by-side Weather + Offline Storage Card (inspired by Refrensi 2)
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: OrganicCard(
                                  tone: OrganicCardTone.warm,
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Icon(
                                            Icons.wb_cloudy_rounded,
                                            size: 20,
                                            color: tokens.surfaceWarmInk,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Cuaca Jalur',
                                            style: textTheme.labelMedium?.copyWith(
                                              color: tokens.surfaceWarmInk,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${route.temperatureC}°C',
                                        style: textTheme.headlineMedium?.copyWith(
                                          color: tokens.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${route.weatherSummary} · +${route.elevationGainM}m',
                                        style: textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: OrganicCard(
                                  tone: route.isDownloaded
                                      ? OrganicCardTone.mint
                                      : OrganicCardTone.flat,
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    controller.toggleRouteOfflineDownload(
                                      route.id,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          route.isDownloaded
                                              ? 'Peta offline ${route.title} dihapus dari penyimpanan lokal.'
                                              : 'Peta offline ${route.title} (${route.offlineSizeMb} MB) tersimpan di perangkat.',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Icon(
                                            route.isDownloaded
                                                ? Icons.offline_pin_rounded
                                                : Icons.download_for_offline_outlined,
                                            size: 20,
                                            color: route.isDownloaded
                                                ? tokens.surfaceMintInk
                                                : tokens.textPrimary,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              route.isDownloaded
                                                  ? 'Siap Offline'
                                                  : 'Unduh Offline',
                                              style: textTheme.labelMedium
                                                  ?.copyWith(
                                                color: route.isDownloaded
                                                    ? tokens.surfaceMintInk
                                                    : tokens.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${route.offlineSizeMb} MB',
                                        style: textTheme.headlineMedium,
                                      ),
                                      Text(
                                        route.isDownloaded
                                            ? 'Tersimpan lokal'
                                            : 'Ketuk untuk simpan',
                                        style: textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Meeting Point Strip
                          OrganicCard(
                            tone: OrganicCardTone.muted,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: tokens.surface,
                                    borderRadius: AppSpacing.badgeBorderRadius,
                                  ),
                                  child: Icon(
                                    Icons.flag_rounded,
                                    color: tokens.surfaceMintInk,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Titik Kumpul (Kode ${route.convoyCode})',
                                        style: textTheme.labelMedium,
                                      ),
                                      Text(
                                        route.meetingPoint,
                                        style: textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Checkpoints Timeline
                          Text(
                            'Checkpoint & Istirahat (${route.checkpoints.length})',
                            style: textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ...List<Widget>.generate(route.checkpoints.length, (i) {
                            final cp = route.checkpoints[i];
                            final isLast = i == route.checkpoints.length - 1;
                            return _CheckpointRow(
                              checkpoint: cp,
                              isLast: isLast,
                            );
                          }),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: tokens.surface,
                boxShadow: !tokens.isRidingMode
                    ? <BoxShadow>[
                        BoxShadow(
                          color: tokens.shadowColor,
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: <Widget>[
                  TactileButton(
                    label: route.isDownloaded ? 'Offline' : 'Unduh',
                    icon: route.isDownloaded
                        ? Icons.check_circle_rounded
                        : Icons.download_rounded,
                    variant: TactileButtonVariant.subtle,
                    height: 56,
                    onPressed: () {
                      controller.toggleRouteOfflineDownload(route.id);
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TactileButton(
                      label: 'Mulai Konvoi di Rute Ini',
                      icon: Icons.navigation_rounded,
                      variant: TactileButtonVariant.primary,
                      height: 56,
                      expanded: true,
                      onPressed: () {
                        controller.startConvoyOnRoute(route.id);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CheckpointRow extends StatelessWidget {
  const _CheckpointRow({
    required this.checkpoint,
    required this.isLast,
  });

  final RouteCheckpoint checkpoint;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 28,
            child: Column(
              children: <Widget>[
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: checkpoint.completed
                        ? AppColors.brandGreenDeep
                        : tokens.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.brandGreenDeep,
                      width: 2.5,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: tokens.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: OrganicCard(
                tone: OrganicCardTone.flat,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            checkpoint.name,
                            style: textTheme.titleSmall,
                          ),
                        ),
                        Text(
                          'KM ${checkpoint.kmMark.toStringAsFixed(1)}',
                          style: textTheme.labelSmall?.copyWith(
                            color: tokens.surfaceMintInk,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${checkpoint.type}: ${checkpoint.note}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
