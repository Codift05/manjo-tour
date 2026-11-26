import '../../core/performance/load_balancer.dart';
import '../../core/performance/memory_cache.dart';
import '../../core/performance/pagination.dart';
import '../models/profile_model.dart';
import '../models/route_model.dart';
import '../models/trip_model.dart';

/// Paginated & Cached Data Repository backed by [LruTtlCache] and [ClientLoadBalancer].
/// Ready to swap simulated local delays with live Golang REST/WebSocket calls with zero UI rewrites.
class TouringRepository {
  TouringRepository({
    required this.loadBalancer,
    LruTtlCache<String, dynamic>? cache,
  }) : cache = cache ?? LruTtlCache<String, dynamic>(maxEntries: 64);

  final ClientLoadBalancer loadBalancer;
  final LruTtlCache<String, dynamic> cache;

  /// Fetches a paginated slice of routes with LRU+TTL caching and load-balanced routing.
  Future<PaginatedSlice<TouringRoute>> fetchRoutesPage({
    required List<TouringRoute> source,
    required int page,
    required int pageSize,
    required String filterSignature,
    Duration simulatedDelay = const Duration(milliseconds: 90),
  }) async {
    final cacheKey = 'routes:$filterSignature:p$page:s$pageSize';
    final cached = cache.get(cacheKey) as PaginatedSlice<TouringRoute>?;
    if (cached != null) {
      return cached.copyWith(fromCache: true);
    }

    final response = await loadBalancer.execute<List<TouringRoute>>(
      dedupeKey: cacheKey,
      task: (node) async {
        if (simulatedDelay > Duration.zero) {
          await Future<void>.delayed(simulatedDelay);
        }
        final start = (page - 1) * pageSize;
        if (start >= source.length) return const <TouringRoute>[];
        final end = (start + pageSize).clamp(0, source.length);
        return source.sublist(start, end);
      },
    );

    final slice = PaginatedSlice<TouringRoute>(
      items: response.data,
      page: page,
      pageSize: pageSize,
      totalItems: source.length,
      servedByNode: response.nodeId,
      fromCache: false,
    );
    cache.put(cacheKey, slice);
    return slice;
  }

  /// Fetches a paginated slice of trips with LRU+TTL caching and load-balanced routing.
  Future<PaginatedSlice<TouringTrip>> fetchTripsPage({
    required List<TouringTrip> source,
    required int page,
    required int pageSize,
    required String filterSignature,
    Duration simulatedDelay = const Duration(milliseconds: 90),
  }) async {
    final cacheKey = 'trips:$filterSignature:p$page:s$pageSize';
    final cached = cache.get(cacheKey) as PaginatedSlice<TouringTrip>?;
    if (cached != null) {
      return cached.copyWith(fromCache: true);
    }

    final response = await loadBalancer.execute<List<TouringTrip>>(
      dedupeKey: cacheKey,
      task: (node) async {
        if (simulatedDelay > Duration.zero) {
          await Future<void>.delayed(simulatedDelay);
        }
        final start = (page - 1) * pageSize;
        if (start >= source.length) return const <TouringTrip>[];
        final end = (start + pageSize).clamp(0, source.length);
        return source.sublist(start, end);
      },
    );

    final slice = PaginatedSlice<TouringTrip>(
      items: response.data,
      page: page,
      pageSize: pageSize,
      totalItems: source.length,
      servedByNode: response.nodeId,
      fromCache: false,
    );
    cache.put(cacheKey, slice);
    return slice;
  }

  /// Fetches a paginated slice of leaderboard entries.
  Future<PaginatedSlice<LeaderboardEntry>> fetchLeaderboardPage({
    required List<LeaderboardEntry> source,
    required int page,
    required int pageSize,
    Duration simulatedDelay = const Duration(milliseconds: 80),
  }) async {
    final cacheKey = 'leaderboard:p$page:s$pageSize';
    final cached = cache.get(cacheKey) as PaginatedSlice<LeaderboardEntry>?;
    if (cached != null) {
      return cached.copyWith(fromCache: true);
    }

    final response = await loadBalancer.execute<List<LeaderboardEntry>>(
      dedupeKey: cacheKey,
      task: (node) async {
        if (simulatedDelay > Duration.zero) {
          await Future<void>.delayed(simulatedDelay);
        }
        final start = (page - 1) * pageSize;
        if (start >= source.length) return const <LeaderboardEntry>[];
        final end = (start + pageSize).clamp(0, source.length);
        return source.sublist(start, end);
      },
    );

    final slice = PaginatedSlice<LeaderboardEntry>(
      items: response.data,
      page: page,
      pageSize: pageSize,
      totalItems: source.length,
      servedByNode: response.nodeId,
      fromCache: false,
    );
    cache.put(cacheKey, slice);
    return slice;
  }

  void invalidateRoutes() =>
      cache.invalidateWhere((k) => k.startsWith('routes:'));

  void invalidateTrips() =>
      cache.invalidateWhere((k) => k.startsWith('trips:'));

  void clearAllCache() => cache.clear();
}
