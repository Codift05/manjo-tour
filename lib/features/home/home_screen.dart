import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/directional_slide_switcher.dart';
import '../../core/widgets/mascot_badge.dart';
import '../../core/widgets/rider_avatar.dart';
import '../../core/widgets/scenic_illustrations.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/tactile_button.dart';
import '../../data/models/route_model.dart';
import '../../state/touring_controller.dart';
import 'all_routes_screen.dart';
import 'convoy_action_modals.dart';
import 'route_detail_sheet.dart';

/// Home / Explore screen crafted faithfully after Refrensi 4.png (Discover):
/// - Generous safe-area clearance below iPhone notch + bold rounded Nunito "Jelajah"
/// - Ultra-efficient compact pure-white Panda Hero Strip (blends 100% seamlessly with static Panda)
/// - 4 warm earthy circular Quick Actions (Gabung, Cari, Radar, Malam) where Cari toggles inline search cleanly
/// - Signature Refrensi 4 pastel full-bleed Route Cards with top-right ribbon tag, dark pill CTA & crisp WebP landscape art
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _carouselController = ScrollController();
  Timer? _searchDebounce;
  bool _showSearch = false;
  bool _offlineOnly = false;

  @override
  void initState() {
    super.initState();
    _carouselController.addListener(_onCarouselScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _carouselController.removeListener(_onCarouselScroll);
    _searchController.dispose();
    _searchFocus.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  /// Auto-prefetches next paginated route slice as the user nears the end of the carousel.
  void _onCarouselScroll() {
    if (!mounted || _offlineOnly || !_carouselController.hasClients) return;
    final pos = _carouselController.position;
    if (pos.pixels >= pos.maxScrollExtent - 140) {
      final controller = TouringScope.read(context);
      if (controller.routesPage.hasMore &&
          !controller.routesPage.isLoadingMore) {
        controller.loadMoreRoutes();
      }
    }
  }

  void _onSearchChanged(TouringController controller, String value) {
    _searchDebounce?.cancel();
    if (value.trim().isEmpty) {
      controller.setSearchQuery('');
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 120), () {
      if (mounted) controller.setSearchQuery(value);
    });
  }

  void _selectCategoryClean(TouringController controller, RouteCategory cat) {
    if (controller.selectedCategory == cat) return;
    HapticFeedback.selectionClick();
    controller.selectCategory(cat);
    if (_carouselController.hasClients) {
      _carouselController.jumpTo(0);
    }
  }

  Future<void> _openAllRoutes(TouringController controller) async {
    HapticFeedback.selectionClick();
    if (controller.routesPage.hasMore) {
      await controller.loadMoreRoutes();
    }
    if (!mounted) return;
    Navigator.of(context).push(
      KonvoiSlidePageRoute<void>(
        builder: (_) => AllRoutesScreen(initialOfflineOnly: _offlineOnly),
      ),
    );
  }

  void _toggleSearch() {
    HapticFeedback.selectionClick();
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch && _searchController.text.isNotEmpty) {
        _searchController.clear();
        TouringScope.read(context).setSearchQuery('');
      }
    });
    if (_showSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    }
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
    final rider = controller.riderProfile;
    final rawRoutes = controller.filteredRoutes;
    final routes = _offlineOnly
        ? rawRoutes.where((r) => r.isDownloaded).toList()
        : rawRoutes;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 680;
          final horizontalPad = isWide ? AppSpacing.xxl : 22.0;

          final isDark = Theme.of(context).brightness == Brightness.dark;

          return CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: <Widget>[
              // 1, 2 & 3. Seamless Single-Color Top Fade Backdrop (NOT a card, zero rounded edge):
              // One solid deep burnt orange (#C24515) smoothly fading by opacity into #F7F6F2
              // behind the Quick Action capsule bar.
              SliverToBoxAdapter(
                child: _TopFadeHeaderSection(
                  horizontalPad: horizontalPad,
                  riderFirstName: rider.name.split(' ').first,
                  riderInitials: rider.initials,
                  riderAvatarAssetPath: rider.avatarAssetPath,
                  activeRoute: controller.activeRoute,
                  memberCount: controller.convoyMembers.length,
                  unreadNotificationCount: controller.unreadNotificationCount,
                  hasGapAlert: controller.hasGapAlert,
                  onAvatarTap: () => controller.selectTab(3),
                  onNotificationsTap: () => showNotificationsModal(context),
                  onStartConvoy: () => showStartConvoyModal(context),
                  onOpenRadar: () => controller.selectTab(1),
                  quickActions: <_QuickActionData>[
                    _QuickActionData(
                      icon: Icons.qr_code_rounded,
                      label: 'Gabung',
                      onTap: () => showJoinCodeModal(context),
                    ),
                    _QuickActionData(
                      icon: _showSearch
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                      label: 'Cari',
                      active: _showSearch,
                      onTap: _toggleSearch,
                    ),
                    _QuickActionData(
                      icon: Icons.offline_pin_outlined,
                      activeIcon: Icons.offline_pin_rounded,
                      label: 'Offline',
                      active: _offlineOnly,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _offlineOnly = !_offlineOnly);
                      },
                    ),
                    _QuickActionData(
                      icon: controller.isRidingMode
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      activeIcon: Icons.light_mode_rounded,
                      label: controller.isRidingMode ? 'Terang' : 'Malam',
                      active: controller.isRidingMode,
                      onTap: controller.toggleRidingMode,
                    ),
                  ],
                ),
              ),

              // Borderless White Search Capsule (single-pass mount, zero sliver height tween)
              if (_showSearch)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPad,
                      0,
                      horizontalPad,
                      14,
                    ),
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
                        focusNode: _searchFocus,
                        onChanged: (v) => _onSearchChanged(controller, v),
                        decoration: InputDecoration(
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: 'Cari rute touring, kota, atau kode...',
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: tokens.textSecondary,
                          ),
                          suffixIcon: controller.searchQuery.isNotEmpty
                              ? IconButton(
                                  tooltip: 'Bersihkan pencarian',
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    controller.setSearchQuery('');
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),

              // 4. Section Header ("Rute Populer" + working "Lihat Semua ->" opening full AllRoutesScreen)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPad,
                  2,
                  horizontalPad,
                  12,
                ),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _offlineOnly ? 'Rute Offline' : 'Rute Populer',
                          style: textTheme.headlineSmall?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _openAllRoutes(controller),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                'Lihat Semua',
                                style: textTheme.labelMedium?.copyWith(
                                  color: tokens.isRidingMode
                                      ? AppColors.ridingAccentOrange
                                      : AppColors.accentAmber,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: tokens.isRidingMode
                                    ? AppColors.ridingAccentOrange
                                    : AppColors.accentAmber,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Modern Borderless Category Pills (unified pill language with FloatingNavBar)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 38,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                    scrollDirection: Axis.horizontal,
                    itemCount: RouteCategory.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = RouteCategory.values[index];
                      final selected = controller.selectedCategory == cat;
                      return _ModernCategoryPill(
                        label: cat.label,
                        selected: selected,
                        onTap: () => _selectCategoryClean(controller, cat),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // 5. Signature Refrensi 4 Tall Organic Tinted Route Cards
              // Non-overlapping edge-to-edge GPU horizontal slide (zero FadeTransition/saveLayer)
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: _showSearch
                      ? math.max(
                          AppSpacing.floatingNavClearance,
                          MediaQuery.viewInsetsOf(context).bottom + 20,
                        )
                      : AppSpacing.floatingNavClearance,
                ),
                sliver: SliverToBoxAdapter(
                  child: DirectionalSlideSwitcher(
                    index: controller.selectedCategory.index,
                    duration: const Duration(milliseconds: 185),
                    backgroundColor: tokens.canvas,
                    child: routes.isEmpty
                        ? Padding(
                            key: ValueKey<String>(
                              'empty-${controller.selectedCategory.name}-$_offlineOnly',
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPad,
                            ),
                            child: KonvoiEmptyState(
                              title: 'Rute belum ditemukan',
                              description: _offlineOnly
                                  ? 'Belum ada rute tersimpan offline di kategori ini.'
                                  : 'Coba kata kunci lain atau tampilkan semua rute.',
                              actionLabel: 'Tampilkan Semua Rute',
                              onAction: () {
                                _searchController.clear();
                                setState(() {
                                  _offlineOnly = false;
                                  _showSearch = false;
                                });
                                controller.clearFilters();
                              },
                            ),
                          )
                        : SizedBox(
                            key: ValueKey<String>(
                              'cards-${controller.selectedCategory.name}-$_offlineOnly',
                            ),
                            height: 326,
                            child: ListView.separated(
                              controller: _carouselController,
                              addAutomaticKeepAlives: false,
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPad,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: routes.length +
                                  (!_offlineOnly &&
                                          controller.routesPage.hasMore
                                      ? 1
                                      : 0),
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                if (index >= routes.length) {
                                  return SizedBox(
                                    width: 170,
                                    child: _LoadMoreRoutesCard(
                                      isLoading:
                                          controller.routesPage.isLoadingMore,
                                      remaining:
                                          controller.routesPage.totalItems -
                                              routes.length,
                                      onLoadMore: controller.loadMoreRoutes,
                                    ),
                                  );
                                }
                                final route = routes[index];
                                return RepaintBoundary(
                                  child: SizedBox(
                                    width: isWide ? 236 : 206,
                                    child: _RefOrganicRouteCard(
                                      index: index,
                                      route: route,
                                      onOpen: () => Navigator.of(context).push(
                                        KonvoiSlidePageRoute<void>(
                                          builder: (_) => RouteDetailScreen(
                                            routeId: route.id,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
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

/// Seamless single-color vertical fade backdrop (ZERO card box, ZERO rounded edge):
/// Uses ONE single deep orange (#C24515, WCAG AA 5.05:1 with white text) in Light Mode
/// dissolving smoothly by opacity straight into the #F7F6F2 canvas behind the Quick Action capsule.
class _TopFadeHeaderSection extends StatelessWidget {
  const _TopFadeHeaderSection({
    required this.horizontalPad,
    required this.riderFirstName,
    required this.riderInitials,
    required this.riderAvatarAssetPath,
    required this.activeRoute,
    required this.memberCount,
    required this.unreadNotificationCount,
    required this.hasGapAlert,
    required this.onAvatarTap,
    required this.onNotificationsTap,
    required this.onStartConvoy,
    required this.onOpenRadar,
    required this.quickActions,
  });

  final double horizontalPad;
  final String riderFirstName;
  final String riderInitials;
  final String? riderAvatarAssetPath;
  final TouringRoute activeRoute;
  final int memberCount;
  final int unreadNotificationCount;
  final bool hasGapAlert;
  final VoidCallback onAvatarTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onStartConvoy;
  final VoidCallback onOpenRadar;
  final List<_QuickActionData> quickActions;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final bool isDark = tokens.isRidingMode;

    // Single solid hue fading smoothly to transparent (0% alpha) into the page canvas
    final Color baseHue =
        isDark ? const Color(0xFF18253A) : const Color(0xFFC24515);

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            baseHue,
            baseHue,
            baseHue.withValues(alpha: 0.72),
            baseHue.withValues(alpha: 0.24),
            baseHue.withValues(alpha: 0.0),
          ],
          stops: const <double>[0.0, 0.52, 0.70, 0.86, 1.0],
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Top Title + Borderless Translucent Notification Bell
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Jelajah',
                      style: textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  TactileIconButton(
                    icon: Icons.notifications_none_rounded,
                    tooltip: 'Notifikasi',
                    size: 46,
                    backgroundColor: isDark
                        ? tokens.surface
                        : Colors.white.withValues(alpha: 0.18),
                    foregroundColor: Colors.white,
                    badgeColor: isDark
                        ? AppColors.accentOrangeDeep
                        : const Color(0xFF2E1F19),
                    badgeCount: unreadNotificationCount,
                    onPressed: onNotificationsTap,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Cardless Greeting Row: Rider Circular WebP Avatar + Copy + Mulai Pill
              Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onAvatarTap();
                    },
                    child: RiderAvatar(
                      size: 62,
                      initials: riderInitials,
                      fallbackColor: const Color(0xFF2E1F19),
                      assetPath: riderAvatarAssetPath,
                      ringColor: Colors.white,
                      ringWidth: 2.5,
                      shadow: <BoxShadow>[
                        BoxShadow(
                          color: isDark
                              ? const Color(0x33000000)
                              : const Color(0x283A1204),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      semanticLabel: 'Avatar profil $riderFirstName',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          hasGapAlert
                              ? 'Formasi Terpisah!'
                              : 'Halo $riderFirstName, gas konvoi!',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${activeRoute.title.replaceFirst('Jalur Puncak ', '')} · $memberCount rider',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  TactileButton(
                    label: hasGapAlert ? 'Radar' : 'Mulai',
                    height: 40,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    onPressed: hasGapAlert ? onOpenRadar : onStartConvoy,
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Quick Actions Capsule floating smoothly over the fading mist edge
              _QuickActionCapsuleBar(items: quickActions),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final VoidCallback onTap;
  final bool active;
}

/// Unified borderless capsule quick-action dock directly mirroring the FloatingNavBar aesthetic:
/// soft white/slate pill container with tactile circular active states while keeping the warm amber icon color.
class _QuickActionCapsuleBar extends StatelessWidget {
  const _QuickActionCapsuleBar({required this.items});

  final List<_QuickActionData> items;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: tokens.isRidingMode ? tokens.surface : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: !tokens.isRidingMode
              ? <BoxShadow>[
                  BoxShadow(
                    color: tokens.shadowColor,
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: items
              .map((item) => Expanded(child: _QuickActionSlot(data: item)))
              .toList(),
        ),
      ),
    );
  }
}

class _QuickActionSlot extends StatefulWidget {
  const _QuickActionSlot({required this.data});

  final _QuickActionData data;

  @override
  State<_QuickActionSlot> createState() => _QuickActionSlotState();
}

class _QuickActionSlotState extends State<_QuickActionSlot> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final item = widget.data;
    final Color activeBg = tokens.isRidingMode
        ? AppColors.brandMintBright
        : const Color(0xFF2B2320);
    final Color activeFg =
        tokens.isRidingMode ? AppColors.backgroundRiding : Colors.white;
    final Color idleIconColor = tokens.isRidingMode
        ? AppColors.brandMintBright
        : AppColors.accentAmber;

    return Semantics(
      button: true,
      selected: item.active,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: item.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.93 : 1.0,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 190),
                curve: Curves.easeOutCubic,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.active
                      ? activeBg
                      : (tokens.isRidingMode
                          ? tokens.surfaceMuted
                          : const Color(0xFFF6F2EC)),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  item.active ? (item.activeIcon ?? item.icon) : item.icon,
                  size: 21,
                  color: item.active ? activeFg : idleIconColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: item.active ? tokens.textPrimary : tokens.textSecondary,
                  fontWeight: item.active ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Borderless modern category pill matching the FloatingNavBar & CTA capsule style.
class _ModernCategoryPill extends StatelessWidget {
  const _ModernCategoryPill({
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
      label: 'Kategori $label',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
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

/// Signature tall pastel-tinted Route Card directly inspired by Refrensi 4.png
/// ("Angkat beban" / "Maraton"): warm pastel body, top-right bookmark ribbon,
/// editorial title + compact dark espresso CTA button, and crisp full-bleed bottom WebP artwork.
class _RefOrganicRouteCard extends StatelessWidget {
  const _RefOrganicRouteCard({
    required this.index,
    required this.route,
    required this.onOpen,
  });

  final int index;
  final TouringRoute route;
  final VoidCallback onOpen;

  Color _cardColor(bool isDark) {
    if (isDark) return AppColors.surfaceRiding;
    return switch (route.category) {
      RouteCategory.mountain => AppColors.cardSage,
      RouteCategory.coast => AppColors.cardCoast,
      RouteCategory.camping => AppColors.cardPine,
      RouteCategory.intercity => AppColors.cardApricot,
      RouteCategory.all => AppColors.cardApricot,
    };
  }

  Color _ribbonColor() {
    return switch (route.category) {
      RouteCategory.mountain => const Color(0xFF3E6B32),
      RouteCategory.coast => const Color(0xFF1D6280),
      RouteCategory.camping => const Color(0xFF286944),
      RouteCategory.intercity => AppColors.ribbonBronze,
      RouteCategory.all => AppColors.ribbonBronze,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final Color bg = _cardColor(tokens.isRidingMode);
    final Color ink =
        tokens.isRidingMode ? AppColors.textPrimaryRiding : AppColors.textPrimaryLight;
    final Color subInk = tokens.isRidingMode
        ? AppColors.textSecondaryRiding
        : const Color(0xFF42362E);
    final String numLabel = index < 9 ? '0${index + 1}' : '${index + 1}';

    return Semantics(
      button: true,
      label:
          '${route.title}, ${route.region}, ${route.distanceKm.toStringAsFixed(0)} kilometer',
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Stack(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 50, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          route.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.22,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${route.distanceKm.toStringAsFixed(0)} km · ${route.formattedDuration}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: subInk,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Compact dark espresso pill CTA matching Refrensi 4 "Let's Go"
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.primaryAction,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            route.isDownloaded ? 'Siap Offline' : 'Lihat Rute',
                            style: textTheme.labelSmall?.copyWith(
                              color: tokens.onPrimaryAction,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Edge-to-edge bottom artwork with smooth top mist blend into pastel card color
                  Stack(
                    children: <Widget>[
                      ScenicIllustration(
                        variant: route.scenicVariant,
                        height: 156,
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 36,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                bg,
                                bg.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Signature Refrensi 4 top-right bookmark ribbon tag
              Positioned(
                top: 0,
                right: 12,
                child: Container(
                  width: 32,
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 8),
                  decoration: BoxDecoration(
                    color: _ribbonColor(),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(10),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    numLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadMoreRoutesCard extends StatelessWidget {
  const _LoadMoreRoutesCard({
    required this.isLoading,
    required this.remaining,
    required this.onLoadMore,
  });

  final bool isLoading;
  final int remaining;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: !tokens.isRidingMode
            ? <BoxShadow>[
                BoxShadow(
                  color: tokens.shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          MascotArt(
            pose: MascotPose.ride,
            size: 78,
            animated: isLoading,
            semanticLabel: 'Muat rute lainnya',
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isLoading ? 'Memuat...' : '+$remaining Rute',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          TactileButton(
            label: isLoading ? 'Memuat' : 'Muat Lagi',
            height: 40,
            borderRadius: BorderRadius.circular(999),
            onPressed: isLoading ? null : onLoadMore,
          ),
        ],
      ),
    );
  }
}
