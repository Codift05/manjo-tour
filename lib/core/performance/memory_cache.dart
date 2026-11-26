import 'dart:collection';

class _CacheEntry<V> {
  _CacheEntry({required this.value, required this.expiresAt});

  final V value;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Bounded Least-Recently-Used (LRU) memory cache with Time-To-Live (TTL) expiration.
/// Prevents unbounded RAM growth while eliminating redundant paginated or route fetches.
class LruTtlCache<K, V> {
  LruTtlCache({
    this.maxEntries = 64,
    this.defaultTtl = const Duration(minutes: 5),
  }) : assert(maxEntries > 0);

  final int maxEntries;
  final Duration defaultTtl;
  final LinkedHashMap<K, _CacheEntry<V>> _store =
      LinkedHashMap<K, _CacheEntry<V>>();

  int _hitCount = 0;
  int _missCount = 0;
  int _evictionCount = 0;

  int get length => _store.length;
  int get hitCount => _hitCount;
  int get missCount => _missCount;
  int get evictionCount => _evictionCount;

  double get hitRate {
    final total = _hitCount + _missCount;
    if (total == 0) return 0;
    return _hitCount / total;
  }

  V? get(K key) {
    final entry = _store.remove(key);
    if (entry == null) {
      _missCount++;
      return null;
    }
    if (entry.isExpired) {
      _missCount++;
      return null;
    }
    // Re-insert at tail to mark as most recently used.
    _store[key] = entry;
    _hitCount++;
    return entry.value;
  }

  void put(K key, V value, {Duration? ttl}) {
    _store.remove(key);
    while (_store.length >= maxEntries) {
      _store.remove(_store.keys.first);
      _evictionCount++;
    }
    _store[key] = _CacheEntry<V>(
      value: value,
      expiresAt: DateTime.now().add(ttl ?? defaultTtl),
    );
  }

  void invalidate(K key) {
    _store.remove(key);
  }

  void invalidateWhere(bool Function(K key) predicate) {
    final keysToRemove = _store.keys.where(predicate).toList();
    for (final k in keysToRemove) {
      _store.remove(k);
    }
  }

  void clear() {
    _store.clear();
  }
}
