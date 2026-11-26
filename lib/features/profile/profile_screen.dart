import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/organic_card.dart';
import '../../core/widgets/rider_avatar.dart';
import '../../core/widgets/scenic_illustrations.dart';
import '../../core/widgets/tactile_button.dart';
import '../../data/models/profile_model.dart';
import '../../state/touring_controller.dart';
import 'network_performance_sheet.dart';
import 'patch_detail_dialog.dart';

String _formatKm(int km) {
  final s = km.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final fromRight = s.length - i;
    buf.write(s[i]);
    if (fromRight > 1 && fromRight % 3 == 1) {
      buf.write('.');
    }
  }
  return '${buf.toString()} km';
}

/// Minimalist Rider Profile & Digital Patches screen unified with Home & Radar:
/// - Seamless single-color burnt-orange top vertical fade (#C24515 -> 0%, zero hard cutoff)
/// - Crisp white top controls, centered RiderAvatar inside a minimal level progress arc
/// - Borderless white mileage capsule floating smoothly over the fading mist edge
/// - Tight zero-gap 2-column Digital Patch collection + clean Leaderboard podium
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Auto-prefetches next paginated leaderboard slice when scrolling near the bottom.
  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 80) {
      final controller = TouringScope.read(context);
      if (controller.leaderboardPage.hasMore &&
          !controller.leaderboardPage.isLoadingMore) {
        controller.loadMoreLeaderboard();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = TouringScope.read(context);
    return ListenableBuilder(
      listenable: controller.profileNotifier,
      builder: (context, _) => _buildContent(context, controller),
    );
  }

  Widget _buildContent(BuildContext context, TouringController controller) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final rider = controller.riderProfile;
    final patches = controller.patches;
    final leaderboard = controller.leaderboard;
    final leaderboardPage = controller.leaderboardPage;
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
            controller: _scrollController,
            slivers: <Widget>[
              // 1. Unified Seamless Single-Color Top Fade Header + Floating Mileage Capsule
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
                          topHue.withValues(alpha: 0.70),
                          topHue.withValues(alpha: 0.20),
                          topHue.withValues(alpha: 0.0),
                        ],
                        stops: const <double>[0.0, 0.56, 0.74, 0.88, 1.0],
                      ),
                    ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPad,
                        16,
                        horizontalPad,
                        18,
                      ),
                      child: Column(
                        children: <Widget>[
                          // Top Bar: Title + Borderless Translucent Glass Actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  'Profil Rider',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.displaySmall?.copyWith(
                                    fontSize: 26,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  TactileIconButton(
                                    icon: Icons.speed_rounded,
                                    tooltip: 'Performa & Load Balancer',
                                    size: 42,
                                    backgroundColor: isDark
                                        ? const Color(0xFF233047)
                                        : Colors.white.withValues(alpha: 0.18),
                                    foregroundColor: Colors.white,
                                    onPressed: () =>
                                        showNetworkPerformanceSheet(context),
                                  ),
                                  const SizedBox(width: 8),
                                  TactileIconButton(
                                    icon: isDark
                                        ? Icons.light_mode_rounded
                                        : Icons.dark_mode_rounded,
                                    tooltip: isDark
                                        ? 'Beralih ke Mode Terang'
                                        : 'Aktifkan Riding Mode',
                                    size: 42,
                                    backgroundColor: isDark
                                        ? const Color(0xFF233047)
                                        : Colors.white.withValues(alpha: 0.18),
                                    foregroundColor: Colors.white,
                                    onPressed: controller.toggleRidingMode,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Centered Rider Avatar inside Clean Level Progress Arc
                          SizedBox(
                            width: 102,
                            height: 102,
                            child: CustomPaint(
                              painter: _LevelArcPainter(
                                progress: rider.levelProgress,
                                trackColor: Colors.white.withValues(alpha: 0.28),
                                arcColor: isDark
                                    ? AppColors.brandMintBright
                                    : Colors.white,
                              ),
                              child: Center(
                                child: RiderAvatar(
                                  size: 80,
                                  initials: rider.initials,
                                  fallbackColor: const Color(0xFF2E1F19),
                                  assetPath: rider.avatarAssetPath,
                                  ringColor: Colors.white,
                                  ringWidth: 2.5,
                                  semanticLabel: 'Avatar ${rider.name}',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            rider.name,
                            style: textTheme.headlineSmall?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Level ${rider.level} ${rider.levelTitle} · ${rider.bikeModel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.90),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Floating Borderless White Mileage Capsule (matches Home Quick Actions dock)
                          OrganicCard(
                            tone: OrganicCardTone.elevated,
                            borderRadius: BorderRadius.circular(24),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: _ProfileMetric(
                                    value: _formatKm(rider.totalKm),
                                    label: 'Total Jarak',
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: tokens.border.withValues(alpha: 0.55),
                                ),
                                Expanded(
                                  child: _ProfileMetric(
                                    value: '${rider.completedTrips}',
                                    label: 'Konvoi Selesai',
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: tokens.border.withValues(alpha: 0.55),
                                ),
                                Expanded(
                                  child: _ProfileMetric(
                                    value: '${rider.zeroGapStreak}x',
                                    label: 'Zero Gap',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ),
              ),

              // 2. Digital Patches Section (zero accidental GridView top padding!)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPad,
                  6,
                  horizontalPad,
                  AppSpacing.floatingNavClearance,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Koleksi Digital Patch',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${patches.where((p) => p.unlocked).length}/${patches.length} terbuka',
                            style: textTheme.labelMedium?.copyWith(
                              color: isDark
                                  ? AppColors.ridingAccentOrange
                                  : AppColors.accentAmber,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: patches.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWide ? 3 : 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: isWide ? 1.08 : 1.0,
                        ),
                        itemBuilder: (context, index) {
                          final patch = patches[index];
                          return RepaintBoundary(
                            child: _PatchCard(
                              patch: patch,
                              onTap: () =>
                                  showPatchDetailDialog(context, patch),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 26),

                      // 3. Paginated Community Distance Leaderboard
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Leaderboard Komunitas',
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '${leaderboard.length}/${leaderboardPage.totalItems} rider',
                            style: textTheme.labelMedium?.copyWith(
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Akumulasi jarak tempuh konvoi bulan ini.',
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      RepaintBoundary(
                        child: _LeaderboardCard(
                          entries: leaderboard,
                          hasMore: leaderboardPage.hasMore,
                          isLoadingMore: leaderboardPage.isLoadingMore,
                          onLoadMore: controller.loadMoreLeaderboard,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _PatchCard extends StatelessWidget {
  const _PatchCard({
    required this.patch,
    required this.onTap,
  });

  final DigitalPatch patch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    return OrganicCard(
      tone: OrganicCardTone.elevated,
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      onTap: onTap,
      semanticLabel:
          '${patch.title}, ${patch.unlocked ? "Terbuka" : "Progres ${(patch.progress * 100).round()} persen"}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Image.asset(
                patch.patchAssetPath,
                width: 72,
                height: 72,
                cacheWidth: 160,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                // Color-modulate alpha directly instead of Opacity() so zero GPU saveLayer is allocated
                color: patch.unlocked ? null : const Color(0x73FFFFFF),
                colorBlendMode: patch.unlocked ? null : BlendMode.modulate,
              ),
              if (!patch.unlocked)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: tokens.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 12,
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            children: <Widget>[
              Text(
                patch.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                patch.subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall,
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: patch.progress,
              minHeight: 4.5,
              backgroundColor: tokens.surfaceMuted,
              color: patch.unlocked
                  ? AppColors.brandGreenDeep
                  : const Color(0xFFC24515),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({
    required this.entries,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  final List<LeaderboardEntry> entries;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    return OrganicCard(
      tone: OrganicCardTone.elevated,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          // Sunset WebP Podium Top 3
          Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              const ScenicIllustration(
                variant: ScenicVariant.leaderboardSunset,
                height: 204,
              ),
              if (top3.length >= 3)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                        child: _PodiumColumn(
                          entry: top3[1],
                          podiumHeight: 62,
                          podiumColor: const Color(0xFF9A3412),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PodiumColumn(
                          entry: top3[0],
                          podiumHeight: 84,
                          podiumColor: const Color(0xFF2E1F19),
                          isWinner: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PodiumColumn(
                          entry: top3[2],
                          podiumHeight: 50,
                          podiumColor: const Color(0xFFC24515),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: <Widget>[
                ...rest.map((entry) {
                  final isUp = entry.rankDelta >= 0;
                  final rankText = entry.rank < 10
                      ? '0${entry.rank}'
                      : '${entry.rank}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: entry.isCurrentUser
                            ? tokens.surfaceWarm
                            : tokens.surfaceMuted.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: 26,
                            child: Text(
                              rankText,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          RiderAvatar(
                            size: 38,
                            initials: entry.initials,
                            fallbackColor: entry.avatarColor,
                            assetPath: entry.avatarAssetPath,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  entry.isCurrentUser
                                      ? '${entry.name} (Anda)'
                                      : entry.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${_formatKm(entry.totalKm)} · ${entry.community}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                isUp
                                    ? '+${entry.rankDelta}'
                                    : '${entry.rankDelta}',
                                style: textTheme.labelSmall?.copyWith(
                                  color: isUp
                                      ? AppColors.brandGreenDeep
                                      : AppColors.dangerRed,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Icon(
                                isUp
                                    ? Icons.arrow_drop_up_rounded
                                    : Icons.arrow_drop_down_rounded,
                                color: isUp
                                    ? AppColors.brandGreenDeep
                                    : AppColors.dangerRed,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (hasMore) ...<Widget>[
                  const SizedBox(height: 4),
                  TactileButton(
                    label: isLoadingMore
                        ? 'Memuat peringkat...'
                        : 'Lihat Peringkat Lainnya',
                    icon: Icons.expand_more_rounded,
                    variant: TactileButtonVariant.subtle,
                    expanded: true,
                    height: 44,
                    onPressed: isLoadingMore ? null : onLoadMore,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.entry,
    required this.podiumHeight,
    required this.podiumColor,
    this.isWinner = false,
  });

  final LeaderboardEntry entry;
  final double podiumHeight;
  final Color podiumColor;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        RiderAvatar(
          size: isWinner ? 50 : 42,
          initials: entry.initials,
          fallbackColor: entry.avatarColor,
          assetPath: entry.avatarAssetPath,
          ringColor: Colors.white,
          ringWidth: 2,
        ),
        const SizedBox(height: 4),
        Text(
          entry.name.split(' ').first,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          _formatKm(entry.totalKm),
          style: const TextStyle(
            color: AppColors.accentEspresso,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: podiumHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: podiumColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            '${entry.rank}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _LevelArcPainter extends CustomPainter {
  const _LevelArcPainter({
    required this.progress,
    required this.trackColor,
    required this.arcColor,
  });

  final double progress;
  final Color trackColor;
  final Color arcColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 4;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LevelArcPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.arcColor != arcColor;
}
