import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/directional_slide_switcher.dart';
import '../../core/widgets/organic_card.dart';
import '../../core/widgets/scenic_illustrations.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/tactile_button.dart';
import '../../data/models/route_model.dart';
import '../../state/touring_controller.dart';
import 'route_detail_sheet.dart';

/// Paginated full catalog screen opened from Home's "Lihat Semua" button:
/// - Unified single-color burnt-orange top fade header
/// - Incremental pagination (5 routes/page) with automatic infinite scroll prefetch + manual button
/// - 120ms debounced search, borderless category pills, 1-tap Offline filter & RepaintBoundary per row
class AllRoutesScreen extends StatefulWidget {
  const AllRoutesScreen({
    super.key,
    this.initialOfflineOnly = false,
  });

  final bool initialOfflineOnly;

  @override
  State<AllRoutesScreen> createState() => _AllRoutesScreenState();
}

class _AllRoutesScreenState extends State<AllRoutesScreen> {
  static const int _pageSize = 5;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  late bool _offlineOnly;
  RouteCategory _localCategory = RouteCategory.all;
  String _localQuery = '';
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _offlineOnly = widget.initialOfflineOnly;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 120) {
      setState(() => _visibleCount += _pageSize);
    }
  }

  void _onQueryChanged(String value) {
    _searchDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _localQuery = '';
        _visibleCount = _pageSize;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() {
          _localQuery = value;
          _visibleCount = _pageSize;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = TouringScope.read(context);
    return ListenableBuilder(
      listenable: controller.homeNotifier,
      builder: (context, _) => _buildContent(context, controller),
    );
  }

  Widget _buildContent(BuildContext context, TouringController controller) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final isDark = tokens.isRidingMode;
    final q = _localQuery.trim().toLowerCase();

    final matched = controller.allRoutes.where((route) {
      final matchesCat = _localCategory == RouteCategory.all ||
          route.category == _localCategory;
      final matchesOffline = !_offlineOnly || route.isDownloaded;
      final matchesQuery = q.isEmpty ||
          route.title.toLowerCase().contains(q) ||
          route.region.toLowerCase().contains(q) ||
          route.convoyCode.toLowerCase().contains(q);
      return matchesCat && matchesOffline && matchesQuery;
    }).toList();

    final visibleRoutes = matched.take(_visibleCount).toList();
    final hasMore = visibleRoutes.length < matched.length;
    final Color topHue =
        isDark ? const Color(0xFF152033) : const Color(0xFFC24515);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: tokens.canvas,
        body: CustomScrollView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: <Widget>[
            // Unified Seamless Top Fade Header + Search + Category Pills
            SliverToBoxAdapter(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      topHue,
                      topHue,
                      topHue.withValues(alpha: 0.65),
                      topHue.withValues(alpha: 0.18),
                      topHue.withValues(alpha: 0.0),
                    ],
                    stops: const <double>[0.0, 0.45, 0.68, 0.85, 1.0],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                        child: Row(
                          children: <Widget>[
                            TactileIconButton(
                              icon: Icons.arrow_back_rounded,
                              tooltip: 'Back',
                              size: 42,
                              backgroundColor: isDark
                                  ? const Color(0xFF233047)
                                  : Colors.white.withValues(alpha: 0.18),
                              foregroundColor: Colors.white,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Semua Rute (${matched.length})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _offlineOnly = !_offlineOnly;
                                  _visibleCount = _pageSize;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _offlineOnly
                                      ? const Color(0xFF2B2320)
                                      : Colors.white.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Icon(
                                      Icons.offline_pin_rounded,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Offline',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Clean White Search Capsule
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: tokens.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: !isDark
                                ? <BoxShadow>[
                                    BoxShadow(
                                      color: tokens.shadowColor,
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onQueryChanged,
                            decoration: InputDecoration(
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              hintText: 'Cari nama rute, kota, atau kode...',
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: tokens.textSecondary,
                              ),
                              suffixIcon: _localQuery.isNotEmpty
                                  ? IconButton(
                                      tooltip: 'Bersihkan pencarian',
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _localQuery = '';
                                          _visibleCount = _pageSize;
                                        });
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),

                      // Modern Borderless Category Pills
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          itemCount: RouteCategory.values.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final cat = RouteCategory.values[index];
                            final selected = _localCategory == cat;
                            final Color activeBg = isDark
                                ? AppColors.brandMintBright
                                : const Color(0xFF2B2320);
                            final Color activeFg = isDark
                                ? AppColors.backgroundRiding
                                : Colors.white;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _localCategory = cat;
                                  _visibleCount = _pageSize;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? activeBg
                                      : (isDark
                                          ? tokens.surface
                                          : Colors.white),
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: !isDark && !selected
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
                                  cat.label,
                                  style: textTheme.labelMedium?.copyWith(
                                    color: selected
                                        ? activeFg
                                        : tokens.textSecondary,
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // Lazy SliverList with Incremental Pagination + RepaintBoundary
            if (visibleRoutes.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: KonvoiEmptyState(
                    title: 'Rute belum ditemukan',
                    description:
                        'Ubah kategori atau kata kunci pencarian untuk melihat daftar rute lainnya.',
                    actionLabel: 'Reset Filter',
                    onAction: () {
                      _searchController.clear();
                      setState(() {
                        _localCategory = RouteCategory.all;
                        _offlineOnly = false;
                        _localQuery = '';
                        _visibleCount = _pageSize;
                      });
                    },
                  ),
                ),
              )
            else ...<Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                sliver: SliverList.separated(
                  itemCount: visibleRoutes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final route = visibleRoutes[index];
                    return RepaintBoundary(
                      child: _CatalogRouteRow(
                        route: route,
                        onTap: () => Navigator.of(context).push(
                          KonvoiSlidePageRoute<void>(
                            builder: (_) =>
                                RouteDetailScreen(routeId: route.id),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                sliver: SliverToBoxAdapter(
                  child: hasMore
                      ? OrganicCard(
                          tone: OrganicCardTone.elevated,
                          borderRadius: BorderRadius.circular(999),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 13,
                          ),
                          onTap: () =>
                              setState(() => _visibleCount += _pageSize),
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
                                  'Muat ${matched.length - visibleRoutes.length} Rute Lainnya',
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
                        )
                      : Center(
                          child: Text(
                            'Semua ${matched.length} rute ditampilkan',
                            style: textTheme.bodySmall,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CatalogRouteRow extends StatelessWidget {
  const _CatalogRouteRow({
    required this.route,
    required this.onTap,
  });

  final TouringRoute route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    return OrganicCard(
      tone: OrganicCardTone.elevated,
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ScenicIllustration(
              variant: route.scenicVariant,
              width: 86,
              height: 80,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: route.isDownloaded
                              ? tokens.surfaceMint
                              : tokens.surfaceMuted,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          route.isDownloaded ? 'Offline' : route.category.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 10.5,
                            color: route.isDownloaded
                                ? tokens.surfaceMintInk
                                : tokens.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        route.convoyCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: tokens.isRidingMode
                              ? AppColors.ridingAccentOrange
                              : AppColors.accentAmber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  route.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${route.region} · ${route.distanceKm.toStringAsFixed(0)} km · ${route.formattedDuration}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
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
