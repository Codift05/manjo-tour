import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/directional_slide_switcher.dart';
import '../../core/widgets/organic_card.dart';
import '../../core/widgets/scenic_illustrations.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/tactile_button.dart';
import '../../data/models/trip_model.dart';
import '../../state/touring_controller.dart';
import 'trip_detail_screen.dart';

String formatRupiah(int amount) {
  final str = amount.toString();
  final buf = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    final posFromRight = str.length - i;
    buf.write(str[i]);
    if (posFromRight > 1 && posFromRight % 3 == 1) {
      buf.write('.');
    }
  }
  return 'Rp${buf.toString()}';
}

/// Minimalist My Trips & Split-Bill screen unified with Home, Radar & Profile:
/// - Seamless single-color burnt-orange top vertical fade (#C24515 -> 0%, zero card cutoff)
/// - Crisp white top bar + borderless translucent glass state-simulator trigger
/// - Borderless modern filter pills floating smoothly over the fading mist edge
/// - Clean uniform white trip cards with circular WebP landscapes, calm soft-tint status badges & zero double-exposure transitions
class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TouringScope.read(context);
    return ListenableBuilder(
      listenable: controller.tripsNotifier,
      builder: (context, _) => _buildContent(context, controller),
    );
  }

  Widget _buildContent(BuildContext context, TouringController controller) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final trips = controller.filteredTrips;
    final isDark = tokens.isRidingMode;
    final Color topHue =
        isDark ? const Color(0xFF152033) : const Color(0xFFC24515);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 680;
          final horizontalPad = isWide ? AppSpacing.xxl : 22.0;

          return CustomScrollView(
            slivers: <Widget>[
              // 1. Unified Seamless Single-Color Top Fade Header + Filter Pills
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          topHue,
                          topHue,
                          topHue.withValues(alpha: 0.68),
                          topHue.withValues(alpha: 0.22),
                          topHue.withValues(alpha: 0.0),
                        ],
                        stops: const <double>[0.0, 0.50, 0.70, 0.86, 1.0],
                      ),
                    ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPad,
                            16,
                            horizontalPad,
                            16,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Perjalanan Saya',
                                      style: textTheme.displaySmall?.copyWith(
                                        fontSize: 26,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Jadwal konvoi, checkpoint, dan patungan grup.',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.90),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Subtle glass menu to inspect loading/error/ready states (R-27)
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF233047)
                                      : Colors.white.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: PopupMenuButton<DataViewMode>(
                                  tooltip: 'Simulasi status data',
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.tune_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  onSelected: controller.setTripsViewMode,
                                  itemBuilder: (_) =>
                                      const <PopupMenuEntry<DataViewMode>>[
                                    PopupMenuItem(
                                      value: DataViewMode.ready,
                                      child: Text('Tampilan Normal'),
                                    ),
                                    PopupMenuItem(
                                      value: DataViewMode.loading,
                                      child: Text('Simulasi Memuat Data'),
                                    ),
                                    PopupMenuItem(
                                      value: DataViewMode.error,
                                      child: Text('Simulasi Gangguan Koneksi'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Borderless Modern Filter Pills floating smoothly over the fading mist edge
                        SizedBox(
                          height: 40,
                          child: ListView(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPad,
                            ),
                            scrollDirection: Axis.horizontal,
                            children: <Widget>[
                              _TripFilterPill(
                                label: 'Semua',
                                selected:
                                    controller.selectedTripFilter == null,
                                onTap: () => controller.selectTripFilter(null),
                              ),
                              const SizedBox(width: 8),
                              ...TripStatus.values.map((status) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _TripFilterPill(
                                    label: status.label,
                                    selected:
                                        controller.selectedTripFilter == status,
                                    onTap: () =>
                                        controller.selectTripFilter(status),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                ),
              ),

              // 2. True Lazy Slivers (zero shrinkWrap overhead) for Ready / Loading / Error / Empty states
              if (controller.tripsViewMode != DataViewMode.ready ||
                  trips.isEmpty)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    4,
                    horizontalPad,
                    AppSpacing.floatingNavClearance,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: KeyedSubtree(
                      key: ValueKey<String>(
                        '${controller.tripsViewMode.name}-${controller.selectedTripFilter?.name ?? "all"}',
                      ),
                      child: switch (controller.tripsViewMode) {
                        DataViewMode.loading => const KonvoiLoadingState(
                            message:
                                'Memuat daftar perjalanan dan catatan patungan...',
                          ),
                        DataViewMode.error => KonvoiErrorState(
                            title: 'Gagal menyinkronkan perjalanan',
                            reason:
                                'Koneksi jaringan sedang terputus. Data perjalanan lokal masih aman dan bisa dicoba ulang.',
                            retryLabel: 'Muat Ulang Perjalanan',
                            onRetry: () =>
                                controller.setTripsViewMode(DataViewMode.ready),
                          ),
                        DataViewMode.ready => KonvoiEmptyState(
                            title: 'Belum ada perjalanan di kategori ini',
                            description:
                                'Pilih kategori lain atau mulai konvoi baru dari Beranda untuk mencatat perjalanan.',
                            actionLabel: 'Tampilkan Semua Perjalanan',
                            onAction: () => controller.selectTripFilter(null),
                          ),
                      },
                    ),
                  ),
                )
              else ...<Widget>[
                if (isWide)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPad,
                      4,
                      horizontalPad,
                      18,
                    ),
                    sliver: SliverGrid.builder(
                      itemCount: trips.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.05,
                      ),
                      itemBuilder: (context, index) => RepaintBoundary(
                        child: _TripGridCard(
                          trip: trips[index],
                          onOpen: () => _openDetail(context, trips[index].id),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPad,
                      4,
                      horizontalPad,
                      18,
                    ),
                    sliver: SliverList.separated(
                      itemCount: trips.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => RepaintBoundary(
                        child: _TripCompactCard(
                          trip: trips[index],
                          onOpen: () => _openDetail(context, trips[index].id),
                        ),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    0,
                    horizontalPad,
                    AppSpacing.floatingNavClearance,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _TripsPaginationFooter(controller: controller),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext context, String tripId) {
    Navigator.of(context).push(
      KonvoiSlidePageRoute<void>(
        builder: (_) => TripDetailScreen(tripId: tripId),
      ),
    );
  }
}

/// Borderless filter pill identical in language to Home's category pills & FloatingNavBar.
class _TripFilterPill extends StatelessWidget {
  const _TripFilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final Color activeBg = tokens.isRidingMode
        ? AppColors.brandMintBright
        : const Color(0xFF2B2320);
    final Color activeFg =
        tokens.isRidingMode ? AppColors.backgroundRiding : Colors.white;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? activeBg
                : (tokens.isRidingMode ? tokens.surface : Colors.white),
            borderRadius: BorderRadius.circular(999),
            boxShadow: !tokens.isRidingMode && !selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: tokens.shadowColor,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              fontSize: 13,
              color: selected ? activeFg : tokens.textSecondary,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TripCompactCard extends StatelessWidget {
  const _TripCompactCard({
    required this.trip,
    required this.onOpen,
  });

  final TouringTrip trip;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final completedCp = trip.checkpoints.where((c) => c.completed).length;
    final cleanDate = trip.dateLabel.replaceFirst(' (Aktif)', '');

    return OrganicCard(
      tone: OrganicCardTone.elevated,
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      onTap: onOpen,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ClipOval(
            child: ScenicIllustration(
              variant: trip.scenicVariant,
              width: 74,
              height: 74,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _TripStatusBadge(status: trip.status),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${trip.distanceKm.toStringAsFixed(0)} km · ${trip.participants.length} rider',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  trip.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cleanDate,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${formatRupiah(trip.perRiderTotalIdr)}/org',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelMedium?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '$completedCp/${trip.checkpoints.length} pos',
                      style: textTheme.labelSmall?.copyWith(
                        color: tokens.isRidingMode
                            ? AppColors.ridingAccentOrange
                            : AppColors.accentAmber,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: tokens.textSecondary.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }
}

class _TripGridCard extends StatelessWidget {
  const _TripGridCard({
    required this.trip,
    required this.onOpen,
  });

  final TouringTrip trip;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cleanDate = trip.dateLabel.replaceFirst(' (Aktif)', '');

    return OrganicCard(
      tone: OrganicCardTone.elevated,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onOpen,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          ClipOval(
            child: ScenicIllustration(
              variant: trip.scenicVariant,
              width: 104,
              height: 104,
            ),
          ),
          Column(
            children: <Widget>[
              _TripStatusBadge(status: trip.status),
              const SizedBox(height: 6),
              Text(
                trip.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${trip.region} · $cleanDate',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall,
              ),
            ],
          ),
          TactileButton(
            label: 'Detail & Patungan',
            height: 42,
            expanded: true,
            borderRadius: BorderRadius.circular(999),
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _TripsPaginationFooter extends StatelessWidget {
  const _TripsPaginationFooter({required this.controller});

  final TouringController controller;

  @override
  Widget build(BuildContext context) {
    final page = controller.tripsPage;
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    if (!page.hasMore) {
      return Center(
        child: Text(
          'Semua ${page.totalItems} perjalanan ditampilkan',
          style: textTheme.bodySmall,
        ),
      );
    }

    return Column(
      children: <Widget>[
        Text(
          'Menampilkan ${page.items.length} dari ${page.totalItems} perjalanan',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        OrganicCard(
          tone: OrganicCardTone.elevated,
          borderRadius: BorderRadius.circular(999),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          onTap: page.isLoadingMore ? null : controller.loadMoreTrips,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.expand_more_rounded,
                size: 19,
                color: tokens.textPrimary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  page.isLoadingMore
                      ? 'Memuat perjalanan...'
                      : 'Muat Perjalanan Lainnya',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Calm soft-tint status badge (WCAG AA >= 4.97:1) replacing loud solid blocks.
class _TripStatusBadge extends StatelessWidget {
  const _TripStatusBadge({required this.status});

  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = context.tokens.isRidingMode;
    final (Color bg, Color fg) = switch (status) {
      TripStatus.active => isDark
          ? (const Color(0xFF133A2C), AppColors.brandMintBright)
          : (const Color(0xFFE5F5EC), const Color(0xFF14693E)),
      TripStatus.upcoming => isDark
          ? (const Color(0xFF331F12), AppColors.ridingAccentOrange)
          : (const Color(0xFFFCECE0), const Color(0xFFB83B0A)),
      TripStatus.completed => isDark
          ? (const Color(0xFF233047), const Color(0xFFCBD5E1))
          : (const Color(0xFFEFECE6), const Color(0xFF524840)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
