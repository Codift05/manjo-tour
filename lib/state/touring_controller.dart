import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/performance/load_balancer.dart';
import '../core/performance/memory_cache.dart';
import '../core/performance/pagination.dart';
import '../data/mock/mock_touring_data.dart';
import '../data/models/convoy_model.dart';
import '../data/models/profile_model.dart';
import '../data/models/route_model.dart';
import '../data/models/trip_model.dart';
import '../data/repositories/touring_repository.dart';

enum DataViewMode { ready, loading, error }

enum MapCameraCommand { zoomIn, zoomOut, reset }

/// Central frontend MVP state controller upgraded with:
/// - Client-side Load Balancer (weighted latency routing + automatic failover + request coalescing)
/// - Bounded LRU + TTL Memory Cache
/// - Incremental Pagination across Routes (4/page), Trips (3/page), and Leaderboard (6/page)
class TouringController extends ChangeNotifier {
  TouringController({
    ClientLoadBalancer? loadBalancer,
    TouringRepository? repository,
    this.simulatedNetworkDelay = Duration.zero,
  }) : loadBalancer = loadBalancer ?? ClientLoadBalancer() {
    _repository =
        repository ?? TouringRepository(loadBalancer: this.loadBalancer);
    _routes = MockTouringData.initialRoutes();
    _convoyMembers = MockTouringData.initialConvoyMembers();
    _hazardPins = MockTouringData.initialHazardPins();
    _trips = MockTouringData.initialTrips();
    _patches = MockTouringData.initialPatches();
    _leaderboard = MockTouringData.initialLeaderboard();
    _notifications = MockTouringData.initialNotifications();
    _activeRouteId = _routes.first.id;

    // Seed initial page-1 slices synchronously so first frame has zero jank
    // while populating cache + load balancer metadata.
    _resetRoutesPaginationSync();
    _resetTripsPaginationSync();
    _resetLeaderboardPaginationSync();
  }

  static const int routePageSize = 4;
  static const int tripPageSize = 3;
  static const int leaderboardPageSize = 6;

  final ClientLoadBalancer loadBalancer;
  late final TouringRepository _repository;
  final Duration simulatedNetworkDelay;

  /// Granular domain notifiers so a tap on one screen NEVER triggers rebuilds on the other 3 screens.
  final ValueNotifier<int> tabNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> ridingModeNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> crashAlertNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> convoyActiveNotifier = ValueNotifier<bool>(true);
  final _DomainNotifier _homeNotifier = _DomainNotifier();
  final _DomainNotifier _radarNotifier = _DomainNotifier();
  final _DomainNotifier _tripsNotifier = _DomainNotifier();
  final _DomainNotifier _profileNotifier = _DomainNotifier();

  Listenable get homeNotifier => _homeNotifier;
  Listenable get radarNotifier => _radarNotifier;
  Listenable get tripsNotifier => _tripsNotifier;
  Listenable get profileNotifier => _profileNotifier;

  int get _currentTab => tabNotifier.value;
  bool get _isRidingMode => ridingModeNotifier.value;
  bool get _convoyActive => convoyActiveNotifier.value;
  bool _isSimulatingMovement = false;
  bool _isTalkingPtt = false;
  bool get _isCrashAlertOpen => crashAlertNotifier.value;
  bool _sosDispatched = false;
  double _mapZoom = 1.0;
  MapCameraCommand _mapCameraCommand = MapCameraCommand.reset;
  int _mapCameraCommandTick = 0;

  void _emit({
    bool home = false,
    bool radar = false,
    bool trips = false,
    bool profile = false,
    bool global = true,
  }) {
    if (home) _homeNotifier.ping();
    if (radar) _radarNotifier.ping();
    if (trips) _tripsNotifier.ping();
    if (profile) _profileNotifier.ping();
    if (global) notifyListeners();
  }

  String _searchQuery = '';
  RouteCategory _selectedCategory = RouteCategory.all;
  TripStatus? _selectedTripFilter;
  DataViewMode _tripsViewMode = DataViewMode.ready;

  late List<TouringRoute> _routes;
  late List<ConvoyMember> _convoyMembers;
  late List<HazardPin> _hazardPins;
  late List<TouringTrip> _trips;
  late List<DigitalPatch> _patches;
  late List<LeaderboardEntry> _leaderboard;
  late List<AppNotification> _notifications;
  late String _activeRouteId;

  late PaginatedSlice<TouringRoute> _routesPage;
  late PaginatedSlice<TouringTrip> _tripsPage;
  late PaginatedSlice<LeaderboardEntry> _leaderboardPage;

  Timer? _simulationTimer;
  int _simTick = 0;

  // Performance / Infrastructure Getters
  LruTtlCache<String, dynamic> get cache => _repository.cache;
  PaginatedSlice<TouringRoute> get routesPage => _routesPage;
  PaginatedSlice<TouringTrip> get tripsPage => _tripsPage;
  PaginatedSlice<LeaderboardEntry> get leaderboardPage => _leaderboardPage;

  // Standard Getters
  int get currentTab => _currentTab;
  bool get isRidingMode => _isRidingMode;
  bool get convoyActive => _convoyActive;
  bool get isSimulatingMovement => _isSimulatingMovement;
  bool get isTalkingPtt => _isTalkingPtt;
  bool get isCrashAlertOpen => _isCrashAlertOpen;
  bool get sosDispatched => _sosDispatched;
  double get mapZoom => _mapZoom;
  MapCameraCommand get mapCameraCommand => _mapCameraCommand;
  int get mapCameraCommandTick => _mapCameraCommandTick;
  String get searchQuery => _searchQuery;
  RouteCategory get selectedCategory => _selectedCategory;
  TripStatus? get selectedTripFilter => _selectedTripFilter;
  DataViewMode get tripsViewMode => _tripsViewMode;

  RiderProfile get riderProfile => MockTouringData.currentRider;
  List<TouringRoute> get allRoutes => List.unmodifiable(_routes);
  List<ConvoyMember> get convoyMembers => List.unmodifiable(_convoyMembers);
  List<HazardPin> get hazardPins => List.unmodifiable(_hazardPins);
  List<TouringTrip> get allTrips => List.unmodifiable(_trips);
  List<DigitalPatch> get patches => List.unmodifiable(_patches);
  List<LeaderboardEntry> get leaderboard =>
      List.unmodifiable(_leaderboardPage.items);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadNotificationCount =>
      _notifications.where((n) => n.unread).length;

  TouringRoute get activeRoute => _routes.firstWhere(
        (r) => r.id == _activeRouteId,
        orElse: () => _routes.first,
      );

  List<TouringRoute> get _matchingRoutes {
    final q = _searchQuery.trim().toLowerCase();
    return _routes.where((route) {
      final matchesCategory = _selectedCategory == RouteCategory.all ||
          route.category == _selectedCategory;
      final matchesQuery = q.isEmpty ||
          route.title.toLowerCase().contains(q) ||
          route.region.toLowerCase().contains(q) ||
          route.convoyCode.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  /// Paginated visible routes for Home carousel.
  List<TouringRoute> get filteredRoutes => List.unmodifiable(_routesPage.items);

  List<TouringTrip> get _matchingTrips {
    if (_selectedTripFilter == null) return List.unmodifiable(_trips);
    return _trips.where((t) => t.status == _selectedTripFilter).toList();
  }

  /// Paginated visible trips for Trips list/grid.
  List<TouringTrip> get filteredTrips => List.unmodifiable(_tripsPage.items);

  int get maxFormationGapMeters {
    if (_convoyMembers.isEmpty) return 0;
    return _convoyMembers.map((m) => m.gapMeters).reduce(math.max);
  }

  ConvoyMember? get laggingMember {
    ConvoyMember? worst;
    for (final m in _convoyMembers) {
      if (m.gapMeters > 500) {
        if (worst == null || m.gapMeters > worst.gapMeters) {
          worst = m;
        }
      }
    }
    return worst;
  }

  bool get hasGapAlert => laggingMember != null;

  // Pagination & Caching helpers
  String get _routeFilterSig => '${_selectedCategory.name}|${_searchQuery.trim().toLowerCase()}';
  String get _tripFilterSig => _selectedTripFilter?.name ?? 'all';

  void _resetRoutesPaginationSync() {
    final source = _matchingRoutes;
    final key = 'routes:$_routeFilterSig:p1:s$routePageSize';
    final cached = cache.get(key) as PaginatedSlice<TouringRoute>?;
    if (cached != null) {
      _routesPage = cached.copyWith(fromCache: true);
      return;
    }
    final firstItems = source.take(routePageSize).toList();
    _routesPage = PaginatedSlice<TouringRoute>(
      items: firstItems,
      page: 1,
      pageSize: routePageSize,
      totalItems: source.length,
      servedByNode: loadBalancer.activePrimaryNode.id,
      fromCache: false,
    );
    cache.put(key, _routesPage);
  }

  void _resetTripsPaginationSync() {
    final source = _matchingTrips;
    final key = 'trips:$_tripFilterSig:p1:s$tripPageSize';
    final cached = cache.get(key) as PaginatedSlice<TouringTrip>?;
    if (cached != null) {
      _tripsPage = cached.copyWith(fromCache: true);
      return;
    }
    final firstItems = source.take(tripPageSize).toList();
    _tripsPage = PaginatedSlice<TouringTrip>(
      items: firstItems,
      page: 1,
      pageSize: tripPageSize,
      totalItems: source.length,
      servedByNode: loadBalancer.activePrimaryNode.id,
      fromCache: false,
    );
    cache.put(key, _tripsPage);
  }

  void _resetLeaderboardPaginationSync() {
    const key = 'leaderboard:p1:s$leaderboardPageSize';
    final cached = cache.get(key) as PaginatedSlice<LeaderboardEntry>?;
    if (cached != null) {
      _leaderboardPage = cached.copyWith(fromCache: true);
      return;
    }
    final firstItems = _leaderboard.take(leaderboardPageSize).toList();
    _leaderboardPage = PaginatedSlice<LeaderboardEntry>(
      items: firstItems,
      page: 1,
      pageSize: leaderboardPageSize,
      totalItems: _leaderboard.length,
      servedByNode: loadBalancer.activePrimaryNode.id,
      fromCache: false,
    );
    cache.put(key, _leaderboardPage);
  }

  Future<void> loadMoreRoutes() async {
    if (!_routesPage.hasMore || _routesPage.isLoadingMore) return;
    _routesPage = _routesPage.copyWith(isLoadingMore: true);
    _emit(home: true);

    final nextPage = _routesPage.page + 1;
    final nextSlice = await _repository.fetchRoutesPage(
      source: _matchingRoutes,
      page: nextPage,
      pageSize: routePageSize,
      filterSignature: _routeFilterSig,
      simulatedDelay: simulatedNetworkDelay,
    );

    _routesPage = PaginatedSlice<TouringRoute>(
      items: <TouringRoute>[..._routesPage.items, ...nextSlice.items],
      page: nextPage,
      pageSize: routePageSize,
      totalItems: nextSlice.totalItems,
      servedByNode: nextSlice.servedByNode,
      fromCache: nextSlice.fromCache,
      isLoadingMore: false,
    );
    _emit(home: true);
  }

  Future<void> loadMoreTrips() async {
    if (!_tripsPage.hasMore || _tripsPage.isLoadingMore) return;
    _tripsPage = _tripsPage.copyWith(isLoadingMore: true);
    _emit(trips: true);

    final nextPage = _tripsPage.page + 1;
    final nextSlice = await _repository.fetchTripsPage(
      source: _matchingTrips,
      page: nextPage,
      pageSize: tripPageSize,
      filterSignature: _tripFilterSig,
      simulatedDelay: simulatedNetworkDelay,
    );

    _tripsPage = PaginatedSlice<TouringTrip>(
      items: <TouringTrip>[..._tripsPage.items, ...nextSlice.items],
      page: nextPage,
      pageSize: tripPageSize,
      totalItems: nextSlice.totalItems,
      servedByNode: nextSlice.servedByNode,
      fromCache: nextSlice.fromCache,
      isLoadingMore: false,
    );
    _emit(trips: true);
  }

  Future<void> loadMoreLeaderboard() async {
    if (!_leaderboardPage.hasMore || _leaderboardPage.isLoadingMore) return;
    _leaderboardPage = _leaderboardPage.copyWith(isLoadingMore: true);
    _emit(profile: true);

    final nextPage = _leaderboardPage.page + 1;
    final nextSlice = await _repository.fetchLeaderboardPage(
      source: _leaderboard,
      page: nextPage,
      pageSize: leaderboardPageSize,
      simulatedDelay: simulatedNetworkDelay,
    );

    _leaderboardPage = PaginatedSlice<LeaderboardEntry>(
      items: <LeaderboardEntry>[..._leaderboardPage.items, ...nextSlice.items],
      page: nextPage,
      pageSize: leaderboardPageSize,
      totalItems: nextSlice.totalItems,
      servedByNode: nextSlice.servedByNode,
      fromCache: nextSlice.fromCache,
      isLoadingMore: false,
    );
    _emit(profile: true);
  }

  /// Toggles health of a backend gateway node and runs a live probe to demonstrate failover.
  Future<void> toggleBackendNodeHealth(String nodeId) async {
    final target = loadBalancer.nodes.firstWhere((n) => n.id == nodeId);
    loadBalancer.setNodeHealth(nodeId, !target.healthy);
    _repository.invalidateRoutes();
    // Run an immediate health-routed fetch so UI reflects failover node right away
    final slice = await _repository.fetchRoutesPage(
      source: _matchingRoutes,
      page: 1,
      pageSize: routePageSize,
      filterSignature: _routeFilterSig,
      simulatedDelay: Duration.zero,
    );
    _routesPage = slice;
    _emit(home: true, profile: true);
  }

  void clearMemoryCache() {
    _repository.clearAllCache();
    _resetRoutesPaginationSync();
    _resetTripsPaginationSync();
    _resetLeaderboardPaginationSync();
    _emit(home: true, trips: true, profile: true);
  }

  // Navigation & Theme
  void selectTab(int index) {
    if (tabNotifier.value == index) return;
    // Update only tabNotifier so ZERO heavy tab screens rebuild during the slide transition!
    tabNotifier.value = index;
  }

  void toggleRidingMode([bool? value]) {
    final next = value ?? !ridingModeNotifier.value;
    if (ridingModeNotifier.value == next) return;
    ridingModeNotifier.value = next;
    _emit(home: true, radar: true, trips: true, profile: true);
  }

  // Search & Category Filtering
  void setSearchQuery(String query) {
    _searchQuery = query;
    _resetRoutesPaginationSync();
    _emit(home: true, global: false);
  }

  void selectCategory(RouteCategory category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _resetRoutesPaginationSync();
    _emit(home: true, global: false);
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = RouteCategory.all;
    _resetRoutesPaginationSync();
    _emit(home: true, global: false);
  }

  // Route Actions & Offline Storage Simulation
  void toggleRouteOfflineDownload(String routeId) {
    _routes = _routes.map((r) {
      if (r.id != routeId) return r;
      return r.copyWith(isDownloaded: !r.isDownloaded);
    }).toList();
    _repository.invalidateRoutes();
    _syncCurrentRoutesSlice();
    _emit(home: true, radar: true);
  }

  void toggleRouteBookmark(String routeId) {
    _routes = _routes.map((r) {
      if (r.id != routeId) return r;
      return r.copyWith(isBookmarked: !r.isBookmarked);
    }).toList();
    _repository.invalidateRoutes();
    _syncCurrentRoutesSlice();
    _emit(home: true);
  }

  void _syncCurrentRoutesSlice() {
    final matched = _matchingRoutes;
    final count = _routesPage.items.length.clamp(0, matched.length);
    _routesPage = _routesPage.copyWith(
      items: matched.take(count == 0 ? routePageSize : count).toList(),
      totalItems: matched.length,
    );
  }

  void startConvoyOnRoute(String routeId) {
    _activeRouteId = routeId;
    convoyActiveNotifier.value = true;
    _sosDispatched = false;
    tabNotifier.value = 1;
    _emit(home: true, radar: true);
  }

  TouringRoute? joinConvoyByCode(String code) {
    final normalized = code.trim().toUpperCase();
    for (final route in _routes) {
      if (route.convoyCode.toUpperCase() == normalized) {
        startConvoyOnRoute(route.id);
        return route;
      }
    }
    return null;
  }

  void markAllNotificationsRead() {
    _notifications =
        _notifications.map((n) => n.copyWith(unread: false)).toList();
    _emit(home: true);
  }

  // Live Radar Controls & Simulation
  void zoomIn() {
    _mapZoom = (_mapZoom + 0.2).clamp(0.8, 1.8);
    _mapCameraCommand = MapCameraCommand.zoomIn;
    _mapCameraCommandTick++;
    _emit(radar: true, global: false);
  }

  void zoomOut() {
    _mapZoom = (_mapZoom - 0.2).clamp(0.8, 1.8);
    _mapCameraCommand = MapCameraCommand.zoomOut;
    _mapCameraCommandTick++;
    _emit(radar: true, global: false);
  }

  void resetZoom() {
    _mapZoom = 1.0;
    _mapCameraCommand = MapCameraCommand.reset;
    _mapCameraCommandTick++;
    _emit(radar: true, global: false);
  }

  void toggleMovementSimulation() {
    if (_isSimulatingMovement) {
      stopMovementSimulation();
    } else {
      _isSimulatingMovement = true;
      _simulationTimer?.cancel();
      _simulationTimer = Timer.periodic(
        const Duration(milliseconds: 900),
        (_) => _advanceConvoyTick(),
      );
      _emit(radar: true, global: false);
    }
  }

  void stopMovementSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    if (_isSimulatingMovement) {
      _isSimulatingMovement = false;
      _emit(radar: true, global: false);
    }
  }

  void _advanceConvoyTick() {
    // Pause simulation ticks when user is not viewing the Radar tab to preserve CPU & battery.
    if (tabNotifier.value != 1) return;
    _simTick++;
    final hadGap = hasGapAlert;
    _convoyMembers = _convoyMembers.map((member) {
      final double baseStep = switch (member.role) {
        RiderRole.leader => 0.018,
        RiderRole.you => 0.016,
        RiderRole.member => 0.015,
        RiderRole.sweeper => (_simTick % 7 < 4) ? 0.008 : 0.022,
      };
      double nextPos = member.routeProgress + baseStep;
      if (nextPos > 0.92) nextPos = 0.14;

      final speedDelta = ((_simTick + member.id.hashCode) % 7) - 3;
      final nextSpeed = (member.speedKmh + speedDelta).clamp(36, 72);

      int nextGap = member.gapMeters;
      if (member.role == RiderRole.sweeper) {
        nextGap = (_simTick % 7 < 4)
            ? (member.gapMeters + 95).clamp(240, 760)
            : (member.gapMeters - 130).clamp(260, 760);
      } else if (member.role == RiderRole.leader) {
        nextGap = (150 + (_simTick % 4) * 20);
      } else if (member.role == RiderRole.member) {
        nextGap = (200 + (_simTick % 5) * 35);
      }

      return member.copyWith(
        routeProgress: nextPos,
        speedKmh: nextSpeed,
        gapMeters: nextGap,
      );
    }).toList();
    _emit(radar: true, home: hasGapAlert != hadGap, global: false);
  }

  void toggleSimulatedGapAlert() {
    final currentlyAlerting = hasGapAlert;
    _convoyMembers = _convoyMembers.map((m) {
      if (m.role == RiderRole.sweeper) {
        return m.copyWith(
          gapMeters: currentlyAlerting ? 310 : 640,
          routeProgress: currentlyAlerting ? 0.30 : 0.14,
          speedKmh: currentlyAlerting ? 52 : 34,
        );
      }
      return m;
    }).toList();
    _emit(radar: true, home: true, global: false);
  }

  void setPttTalking(bool talking) {
    if (_isTalkingPtt == talking) return;
    _isTalkingPtt = talking;
    _convoyMembers = _convoyMembers.map((m) {
      if (m.role == RiderRole.you) {
        return m.copyWith(isSpeaking: talking);
      }
      return m;
    }).toList();
    _emit(radar: true, global: false);
  }

  void addHazardPin(HazardType type, {String? customNote}) {
    final you = _convoyMembers.firstWhere(
      (m) => m.role == RiderRole.you,
      orElse: () => _convoyMembers.first,
    );
    final pin = HazardPin(
      id: 'hz-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      reporterName: 'Mip (You)',
      routeProgress: (you.routeProgress + 0.07).clamp(0.12, 0.90),
      lateralOffset: (_hazardPins.length.isEven ? -0.07 : 0.07),
      timeLabel: 'Baru saja',
      note: (customNote != null && customNote.trim().isNotEmpty)
          ? customNote.trim()
          : type.shortNote,
    );
    _hazardPins = <HazardPin>[pin, ..._hazardPins];
    _emit(radar: true, global: false);
  }

  void removeHazardPin(String pinId) {
    _hazardPins = _hazardPins.where((p) => p.id != pinId).toList();
    _emit(radar: true, global: false);
  }

  void openCrashSimulation() {
    crashAlertNotifier.value = true;
    _sosDispatched = false;
    _emit(radar: true, global: false);
  }

  void cancelCrashAlert() {
    crashAlertNotifier.value = false;
    _sosDispatched = false;
    _emit(radar: true, global: false);
  }

  void dispatchSosSignal() {
    _sosDispatched = true;
    _notifications = <AppNotification>[
      AppNotification(
        id: 'sos-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Sinyal SOS Terkirim ke Grup',
        body:
            'Koordinat 1.3236, 124.8389 dibagikan ke seluruh anggota ${activeRoute.convoyCode}.',
        timeLabel: 'Baru saja',
        icon: Icons.sos_rounded,
      ),
      ..._notifications,
    ];
    _emit(radar: true, home: true);
  }

  // Trips & Split-Bill
  void selectTripFilter(TripStatus? status) {
    if (_selectedTripFilter == status) return;
    _selectedTripFilter = status;
    _resetTripsPaginationSync();
    _emit(trips: true, global: false);
  }

  void setTripsViewMode(DataViewMode mode) {
    if (_tripsViewMode == mode) return;
    _tripsViewMode = mode;
    _emit(trips: true, global: false);
  }

  TouringTrip? findTrip(String tripId) {
    for (final trip in _trips) {
      if (trip.id == tripId) return trip;
    }
    return null;
  }

  void _syncCurrentTripsSlice() {
    final matched = _matchingTrips;
    final count = _tripsPage.items.length.clamp(0, matched.length);
    _tripsPage = _tripsPage.copyWith(
      items: matched.take(count == 0 ? tripPageSize : count).toList(),
      totalItems: matched.length,
    );
  }

  void toggleCheckpointCompleted(String tripId, int checkpointIndex) {
    _trips = _trips.map((trip) {
      if (trip.id != tripId) return trip;
      final updated = List<RouteCheckpoint>.from(trip.checkpoints);
      if (checkpointIndex >= 0 && checkpointIndex < updated.length) {
        updated[checkpointIndex] = updated[checkpointIndex].copyWith(
          completed: !updated[checkpointIndex].completed,
        );
      }
      return trip.copyWith(checkpoints: updated);
    }).toList();
    _repository.invalidateTrips();
    _syncCurrentTripsSlice();
    _emit(trips: true);
  }

  void toggleExpenseMemberPaid(
    String tripId,
    String expenseId,
    String memberId,
  ) {
    _trips = _trips.map((trip) {
      if (trip.id != tripId) return trip;
      final updatedExpenses = trip.expenses.map((exp) {
        if (exp.id != expenseId) return exp;
        return exp.toggleMemberPaid(memberId);
      }).toList();
      return trip.copyWith(expenses: updatedExpenses);
    }).toList();
    _repository.invalidateTrips();
    _syncCurrentTripsSlice();
    _emit(trips: true);
  }

  void addTripExpense({
    required String tripId,
    required String title,
    required ExpenseCategory category,
    required int amountIdr,
    required String paidById,
  }) {
    _trips = _trips.map((trip) {
      if (trip.id != tripId) return trip;
      final paymentMap = <String, bool>{
        for (final p in trip.participants) p.id: p.id == paidById,
      };
      final newExpense = TripExpense(
        id: 'exp-${DateTime.now().millisecondsSinceEpoch}',
        title: title.trim(),
        category: category,
        amountIdr: amountIdr,
        paidById: paidById,
        timeLabel: 'Baru saja',
        paidStatusByMemberId: paymentMap,
      );
      return trip.copyWith(expenses: <TripExpense>[newExpense, ...trip.expenses]);
    }).toList();
    _repository.invalidateTrips();
    _syncCurrentTripsSlice();
    _emit(trips: true);
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    tabNotifier.dispose();
    ridingModeNotifier.dispose();
    crashAlertNotifier.dispose();
    convoyActiveNotifier.dispose();
    _homeNotifier.dispose();
    _radarNotifier.dispose();
    _tripsNotifier.dispose();
    _profileNotifier.dispose();
    super.dispose();
  }
}

class _DomainNotifier extends ChangeNotifier {
  void ping() => notifyListeners();
}

class TouringScope extends InheritedNotifier<TouringController> {
  const TouringScope({
    super.key,
    required TouringController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Subscribes to global controller notifications (used by pushed detail routes & modals).
  static TouringController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TouringScope>();
    assert(scope != null, 'TouringScope not found in widget tree');
    return scope!.notifier!;
  }

  /// Reads the controller WITHOUT subscribing to global rebuilds.
  /// Pair with [ListenableBuilder] on a granular domain notifier for zero cross-tab rebuilds.
  static TouringController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<TouringScope>();
    assert(scope != null, 'TouringScope not found in widget tree');
    return scope!.notifier!;
  }
}
