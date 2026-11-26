import 'dart:async';
import 'dart:math' as math;

/// Represents a regional API / WebSocket gateway endpoint in the client load balancer pool.
class BackendNode {
  BackendNode({
    required this.id,
    required this.region,
    required this.endpoint,
    required this.weight,
    required this.latencyMs,
    this.healthy = true,
  });

  final String id;
  final String region;
  final String endpoint;
  final int weight;
  int latencyMs;
  bool healthy;
  int consecutiveFailures = 0;
  DateTime? circuitOpenUntil;

  bool get isAvailable {
    if (!healthy) return false;
    if (circuitOpenUntil != null && DateTime.now().isBefore(circuitOpenUntil!)) {
      return false;
    }
    return true;
  }

  /// Score balancing node weight against current latency (higher is preferred).
  double get routingScore {
    if (!isAvailable) return -1;
    return (weight * 100.0) / math.max(12, latencyMs);
  }
}

class LoadBalancedResponse<T> {
  const LoadBalancedResponse({
    required this.data,
    required this.nodeId,
    required this.latencyMs,
    required this.fromCache,
    this.failedOver = false,
  });

  final T data;
  final String nodeId;
  final int latencyMs;
  final bool fromCache;
  final bool failedOver;
}

/// Client-side resilient Load Balancer with:
/// - Weighted latency-aware node selection across regional endpoints
/// - Circuit breaker & automatic failover when a node degrades
/// - In-flight request coalescing (deduplication) so simultaneous identical fetches share one call
class ClientLoadBalancer {
  ClientLoadBalancer({List<BackendNode>? nodes})
      : _nodes = nodes ??
            <BackendNode>[
              BackendNode(
                id: 'id-jkt-1',
                region: 'Jakarta Primary',
                endpoint: 'https://jkt1.api.konvoi.id',
                weight: 5,
                latencyMs: 24,
              ),
              BackendNode(
                id: 'id-mdo-2',
                region: 'Manado Edge',
                endpoint: 'https://mdo2.api.konvoi.id',
                weight: 4,
                latencyMs: 28,
              ),
              BackendNode(
                id: 'sg-edge-3',
                region: 'Singapore Failover',
                endpoint: 'https://sg3.api.konvoi.id',
                weight: 3,
                latencyMs: 48,
              ),
            ];

  final List<BackendNode> _nodes;
  final Map<String, Future<dynamic>> _inFlight = <String, Future<dynamic>>{};

  int _totalRequests = 0;
  int _failoverCount = 0;
  int _coalescedCount = 0;
  String _lastServedNodeId = 'id-jkt-1';
  int _roundRobinCursor = 0;

  List<BackendNode> get nodes => List.unmodifiable(_nodes);
  int get totalRequests => _totalRequests;
  int get failoverCount => _failoverCount;
  int get coalescedCount => _coalescedCount;
  String get lastServedNodeId => _lastServedNodeId;

  BackendNode get activePrimaryNode {
    final available = _nodes.where((n) => n.isAvailable).toList();
    if (available.isEmpty) return _nodes.first;
    available.sort((a, b) => b.routingScore.compareTo(a.routingScore));
    return available.first;
  }

  /// Toggles a node's health (useful to verify automatic failover in UI & tests).
  void setNodeHealth(String nodeId, bool healthy) {
    for (final node in _nodes) {
      if (node.id == nodeId) {
        node.healthy = healthy;
        if (healthy) {
          node.consecutiveFailures = 0;
          node.circuitOpenUntil = null;
        }
      }
    }
  }

  /// Executes [task] through the healthiest available node, deduplicating concurrent calls
  /// with the same [dedupeKey] and automatically failing over if the chosen node errors.
  Future<LoadBalancedResponse<T>> execute<T>({
    required String dedupeKey,
    required Future<T> Function(BackendNode node) task,
  }) async {
    final existing = _inFlight[dedupeKey];
    if (existing != null) {
      _coalescedCount++;
      return await existing as LoadBalancedResponse<T>;
    }

    final future = _runWithFailover<T>(task);
    _inFlight[dedupeKey] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(dedupeKey);
    }
  }

  Future<LoadBalancedResponse<T>> _runWithFailover<T>(
    Future<T> Function(BackendNode node) task,
  ) async {
    _totalRequests++;

    // Sort candidates by routing score with slight round-robin fairness among top healthy nodes.
    final candidates = _nodes.where((n) => n.isAvailable).toList();
    if (candidates.isEmpty) {
      // Half-open recovery probe on all nodes when every circuit is tripped.
      candidates.addAll(_nodes);
    } else {
      candidates.sort((a, b) => b.routingScore.compareTo(a.routingScore));
      if (candidates.length > 1 && _roundRobinCursor.isOdd) {
        final top = candidates.removeAt(0);
        candidates.insert(1, top);
      }
      _roundRobinCursor++;
    }

    Object? lastError;
    bool didFailover = false;

    for (int i = 0; i < candidates.length; i++) {
      final node = candidates[i];
      if (!node.healthy) {
        didFailover = true;
        _failoverCount++;
        continue;
      }
      try {
        final result = await task(node);
        node.consecutiveFailures = 0;
        node.circuitOpenUntil = null;
        _lastServedNodeId = node.id;
        return LoadBalancedResponse<T>(
          data: result,
          nodeId: node.id,
          latencyMs: node.latencyMs,
          fromCache: false,
          failedOver: didFailover || i > 0,
        );
      } catch (err) {
        lastError = err;
        node.consecutiveFailures++;
        if (node.consecutiveFailures >= 2) {
          node.circuitOpenUntil =
              DateTime.now().add(const Duration(seconds: 20));
        }
        didFailover = true;
        _failoverCount++;
      }
    }

    throw StateError('Semua node load balancer tidak dapat dijangkau: $lastError');
  }
}
