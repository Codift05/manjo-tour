import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Curated real-world Sulawesi Utara GPS waypoints for all 8 touring routes,
/// enhanced asynchronously via the free key-less OSRM driving geometry API
/// (router.project-osrm.org) with geometry decimation (<=140 vertices) and
/// precomputed cumulative distance tables for O(log n) 60fps marker interpolation.
class SulutRouteGeometry {
  SulutRouteGeometry._();

  static const Distance _distance = Distance();
  static final Map<String, List<LatLng>> _roadCache = <String, List<LatLng>>{};
  static final Map<String, Future<List<LatLng>>> _inFlight =
      <String, Future<List<LatLng>>>{};

  /// Precomputed cumulative geodesic distances cached once per path instance (0 trig per frame).
  static final Expando<List<double>> _cumulativeCache =
      Expando<List<double>>('cumulativeDistances');

  /// Primary real-world Sulawesi Utara corridor coordinates per route ID.
  static const Map<String, List<LatLng>> _curatedWaypoints =
      <String, List<LatLng>>{
    // 1. SPBU Winangun Manado -> Tinoor -> Tomohon -> Rurukan Highland -> Puncak Mahawu
    'route-tomohon': <LatLng>[
      LatLng(1.4488, 124.8355), // SPBU Winangun, Manado
      LatLng(1.3992, 124.8364), // Rest Area Tinoor View
      LatLng(1.3264, 124.8392), // Pusat Kota Tomohon
      LatLng(1.3248, 124.8648), // Warung Kopi Rurukan
      LatLng(1.3532, 124.8590), // Pos Finish Puncak Mahawu
    ],
    // 2. Ring Road Kairagi -> Mapanget -> Talawaan -> Likupang Timur -> Pantai Paal
    'route-likupang': <LatLng>[
      LatLng(1.4945, 124.8725), // Ring Road Kairagi
      LatLng(1.5095, 124.9180), // Mapanget
      LatLng(1.5350, 124.9560), // Simpang Talawaan
      LatLng(1.6375, 125.1180), // SPBU Likupang Timur
      LatLng(1.6540, 125.1575), // Pantai Paal Likupang
    ],
    // 3. Boulevard Megamas -> Tinoor -> Tomohon -> Pesisir Danau Tondano
    'route-tondano': <LatLng>[
      LatLng(1.4832, 124.8342), // Boulevard Megamas Manado
      LatLng(1.3992, 124.8358), // Tinoor
      LatLng(1.3264, 124.8392), // Pasar Beriman Tomohon
      LatLng(1.3045, 124.9110), // Kota Tondano
      LatLng(1.2245, 124.8835), // Pesisir Camp Danau Tondano
    ],
    // 4. Jembatan Soekarno Manado -> Tanawangko -> Amurang -> Inobonto -> Kotamobagu
    'route-kotamobagu': <LatLng>[
      LatLng(1.4978, 124.8418), // Jembatan Soekarno Manado
      LatLng(1.4040, 124.6775), // Pesisir Tanawangko
      LatLng(1.1865, 124.5735), // Rest Area Amurang
      LatLng(0.9165, 124.1010), // SPBU Inobonto
      LatLng(0.7335, 124.3165), // Alun-Alun Kotamobagu
    ],
    // 5. Zero Point Manado -> Pineleng -> Kakaskasen -> Kaki Gunung Lokon
    'route-lokon': <LatLng>[
      LatLng(1.4932, 124.8412), // Zero Point Manado
      LatLng(1.4240, 124.8285), // Pineleng
      LatLng(1.3992, 124.8358), // Tinoor
      LatLng(1.3510, 124.8368), // Pos Kakaskasen
      LatLng(1.3585, 124.8125), // Ampiteater Kaki Lokon
    ],
    // 6. Terminal Paal Dua -> Sukur -> Kauditan -> Pantai Firdaus Kema
    'route-kema': <LatLng>[
      LatLng(1.4925, 124.8635), // Terminal Paal Dua
      LatLng(1.4585, 124.9480), // Sukur Minahasa Utara
      LatLng(1.4190, 125.0415), // Rest Area Kauditan
      LatLng(1.3545, 125.0750), // Pantai Firdaus Kema
    ],
    // 7. Malalayang Beach Walk -> Pineleng -> Tomohon -> Danau Linow
    'route-linow': <LatLng>[
      LatLng(1.4605, 124.8015), // Malalayang Beach Walk
      LatLng(1.4240, 124.8285), // Simpang Pineleng
      LatLng(1.3264, 124.8392), // Tomohon
      LatLng(1.2698, 124.8286), // Camp Danau Linow Lahendong
    ],
    // 8. Airmadidi Square -> Kauditan -> Girian -> Pelabuhan Lembeh Bitung
    'route-manado-bitung': <LatLng>[
      LatLng(1.4305, 124.9820), // Airmadidi Square
      LatLng(1.4260, 125.0420), // Kauditan
      LatLng(1.4395, 125.1210), // Pasar Girian Bitung
      LatLng(1.4445, 125.1885), // Pelabuhan Lembeh Bitung
    ],
  };

  /// Synchronous baseline path (cached OSRM geometry if ready, otherwise curated Sulut waypoints).
  static List<LatLng> immediatePolyline(String routeId) {
    final cached = _roadCache[routeId];
    if (cached != null && cached.length >= 2) {
      return cached;
    }
    return _curatedWaypoints[routeId] ?? _curatedWaypoints['route-tomohon']!;
  }

  /// Fetches real road-hugging geometry from the free public OSRM API once per routeId,
  /// decimated cleanly to <=140 points for GPU PolylineLayer speed.
  static Future<List<LatLng>?> fetchFreeOsrmPolyline(String routeId) {
    if (_roadCache.containsKey(routeId)) {
      return Future<List<LatLng>?>.value(_roadCache[routeId]);
    }
    final existing = _inFlight[routeId];
    if (existing != null) {
      return existing;
    }

    final future = _queryOsrm(routeId).whenComplete(() {
      _inFlight.remove(routeId);
    });
    _inFlight[routeId] = future;
    return future;
  }

  static List<LatLng> _decimate(List<LatLng> points, {int maxPoints = 140}) {
    if (points.length <= maxPoints) return List<LatLng>.unmodifiable(points);
    final result = <LatLng>[points.first];
    final double step = (points.length - 1) / (maxPoints - 1);
    for (int i = 1; i < maxPoints - 1; i++) {
      result.add(points[(i * step).round()]);
    }
    result.add(points.last);
    return List<LatLng>.unmodifiable(result);
  }

  static Future<List<LatLng>> _queryOsrm(String routeId) async {
    final fallback = immediatePolyline(routeId);
    final coordsParam = fallback
        .map(
          (p) =>
              '${p.longitude.toStringAsFixed(5)},${p.latitude.toStringAsFixed(5)}',
        )
        .join(';');
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coordsParam'
      '?overview=simplified&geometries=geojson',
    );

    try {
      final response = await http
          .get(
            uri,
            headers: const <String, String>{
              'User-Agent': 'KonvoiTouringApp/1.0',
            },
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        return fallback;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return fallback;
      }
      final routes = decoded['routes'];
      if (routes is! List || routes.isEmpty) {
        return fallback;
      }
      final firstRoute = routes.first as Map<String, dynamic>;
      final geometry = firstRoute['geometry'] as Map<String, dynamic>?;
      final rawCoords = geometry?['coordinates'] as List<dynamic>?;
      if (rawCoords == null || rawCoords.length < 2) {
        return fallback;
      }

      final parsed = <LatLng>[];
      for (final item in rawCoords) {
        if (item is List && item.length >= 2) {
          final lon = (item[0] as num).toDouble();
          final lat = (item[1] as num).toDouble();
          parsed.add(LatLng(lat, lon));
        }
      }
      if (parsed.length >= 2) {
        _roadCache[routeId] = _decimate(parsed);
        return _roadCache[routeId]!;
      }
    } catch (_) {
      // Offline, test sandbox, or rate limit: preserve curated Sulawesi Utara fallback silently.
    }
    return fallback;
  }

  static List<double> _cumulativeDistances(List<LatLng> path) {
    final cached = _cumulativeCache[path];
    if (cached != null) return cached;

    final cum = List<double>.filled(path.length, 0.0);
    double acc = 0.0;
    for (int i = 0; i < path.length - 1; i++) {
      acc += _distance.as(LengthUnit.Meter, path[i], path[i + 1]);
      cum[i + 1] = acc;
    }
    _cumulativeCache[path] = cum;
    return cum;
  }

  /// Evaluates normalized progress [t] (0.0 -> 1.0) along [path] in O(log n)
  /// with cached cumulative geodesic distances (0 Haversine trig calls per frame).
  static LatLng pointAlongPath(
    List<LatLng> path,
    double t, {
    double lateral = 0.0,
  }) {
    if (path.isEmpty) return const LatLng(1.3264, 124.8392);
    if (path.length == 1) return path.first;

    final clamped = t.clamp(0.0, 1.0);
    final cum = _cumulativeDistances(path);
    final totalMeters = cum.last;
    if (totalMeters <= 0.0) return path.first;

    final targetMeters = clamped * totalMeters;

    // Binary search segment containing targetMeters
    int lo = 0;
    int hi = path.length - 2;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (cum[mid + 1] < targetMeters) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }

    final segStartDist = cum[lo];
    final segLen = cum[lo + 1] - segStartDist;
    final localT = segLen > 0
        ? ((targetMeters - segStartDist) / segLen).clamp(0.0, 1.0)
        : 0.0;
    final segStart = path[lo];
    final segEnd = path[lo + 1];

    final point = LatLng(
      segStart.latitude + (segEnd.latitude - segStart.latitude) * localT,
      segStart.longitude + (segEnd.longitude - segStart.longitude) * localT,
    );

    if (lateral == 0.0) return point;

    final dLat = segEnd.latitude - segStart.latitude;
    final dLon = segEnd.longitude - segStart.longitude;
    final norm = math.sqrt(dLat * dLat + dLon * dLon);
    if (norm <= 1e-6) return point;
    final offsetScale = lateral * 0.012;
    return LatLng(
      point.latitude + (-dLon / norm) * offsetScale,
      point.longitude + (dLat / norm) * offsetScale,
    );
  }
}
