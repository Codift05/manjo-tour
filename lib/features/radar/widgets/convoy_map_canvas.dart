import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rider_avatar.dart';
import '../../../data/models/convoy_model.dart';
import '../../../data/models/route_model.dart';
import '../../../data/services/sulut_route_geometry.dart';
import '../../../state/touring_controller.dart';

/// Real interactive cartographic map powered by FlutterMap + CartoDB Voyager/Dark Matter tiles
/// and free key-less OSRM road-snapping over North Sulawesi (Sulawesi Utara),
/// color-graded to match Refrensi 6.png's warm alabaster minimalism and dark Riding Mode.
class ConvoyMapCanvas extends StatefulWidget {
  const ConvoyMapCanvas({
    super.key,
    required this.route,
    required this.members,
    required this.hazardPins,
    required this.cameraCommand,
    required this.cameraCommandTick,
    required this.hasGapAlert,
    required this.onTapHazard,
    required this.onTapMember,
  });

  final TouringRoute route;
  final List<ConvoyMember> members;
  final List<HazardPin> hazardPins;
  final MapCameraCommand cameraCommand;
  final int cameraCommandTick;
  final bool hasGapAlert;
  final ValueChanged<HazardPin> onTapHazard;
  final ValueChanged<ConvoyMember> onTapMember;

  @override
  State<ConvoyMapCanvas> createState() => _ConvoyMapCanvasState();
}

class _ConvoyMapCanvasState extends State<ConvoyMapCanvas>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final NetworkTileProvider _tileProvider;
  late List<LatLng> _routePoints;
  bool _mapReady = false;
  bool _tilesEnabled = false;
  Timer? _tileActivationTimer;

  AnimationController? _cameraAnimController;
  VoidCallback? _cameraAnimListener;

  @override
  void initState() {
    super.initState();
    _tileProvider = NetworkTileProvider(silenceExceptions: true);
    _routePoints = SulutRouteGeometry.immediatePolyline(widget.route.id);
    _upgradeRouteWithOsrm(widget.route.id);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Never fetch/rasterize heavy map tiles while offstage OR during the 175ms tab-entry slide.
    // Once Radar becomes active (TickerMode.enabled == true), activate tiles right after the slide finishes.
    if (!_tilesEnabled && TickerMode.valuesOf(context).enabled && _tileActivationTimer == null) {
      _tileActivationTimer = Timer(const Duration(milliseconds: 190), () {
        if (!mounted) return;
        setState(() => _tilesEnabled = true);
      });
    }
  }

  @override
  void didUpdateWidget(covariant ConvoyMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.route.id != oldWidget.route.id) {
      _routePoints = SulutRouteGeometry.immediatePolyline(widget.route.id);
      _upgradeRouteWithOsrm(widget.route.id);
      if (_mapReady) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fitRouteAnimated();
        });
      }
    } else if (widget.cameraCommandTick != oldWidget.cameraCommandTick &&
        _mapReady) {
      _handleCameraCommand(widget.cameraCommand);
    }
  }

  @override
  void dispose() {
    _tileActivationTimer?.cancel();
    _stopCameraAnimation();
    _tileProvider.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _upgradeRouteWithOsrm(String routeId) async {
    final osrmPoints = await SulutRouteGeometry.fetchFreeOsrmPolyline(routeId);
    if (!mounted || widget.route.id != routeId || osrmPoints == null) return;
    if (osrmPoints.length > _routePoints.length) {
      setState(() {
        _routePoints = osrmPoints;
      });
    }
  }

  LatLngBounds _boundsForPoints(List<LatLng> points) {
    return LatLngBounds.fromPoints(
      points.isEmpty ? const <LatLng>[LatLng(1.3264, 124.8392)] : points,
    );
  }

  CameraFit _defaultCameraFit(BuildContext context, List<LatLng> points) {
    final double topInset = MediaQuery.paddingOf(context).top;
    return CameraFit.bounds(
      bounds: _boundsForPoints(points),
      padding: EdgeInsets.fromLTRB(56, topInset + 236, 56, 274),
      maxZoom: 13.8,
    );
  }

  void _handleCameraCommand(MapCameraCommand command) {
    final cam = _mapController.camera;
    switch (command) {
      case MapCameraCommand.zoomIn:
        _animateCameraTo(cam.center, (cam.zoom + 0.85).clamp(8.5, 17.5));
      case MapCameraCommand.zoomOut:
        _animateCameraTo(cam.center, (cam.zoom - 0.85).clamp(8.5, 17.5));
      case MapCameraCommand.reset:
        _fitRouteAnimated();
    }
  }

  void _fitRouteAnimated() {
    final target =
        _defaultCameraFit(context, _routePoints).fit(_mapController.camera);
    _animateCameraTo(target.center, target.zoom);
  }

  void _stopCameraAnimation() {
    if (_cameraAnimListener != null) {
      _cameraAnimController?.removeListener(_cameraAnimListener!);
      _cameraAnimListener = null;
    }
    _cameraAnimController?.dispose();
    _cameraAnimController = null;
  }

  void _animateCameraTo(LatLng destCenter, double destZoom) {
    _stopCameraAnimation();
    final Duration duration = AppMotion.effective(
      context,
      const Duration(milliseconds: 260),
    );
    final startCenter = _mapController.camera.center;
    final startZoom = _mapController.camera.zoom;

    if (duration == Duration.zero) {
      _mapController.move(destCenter, destZoom);
      return;
    }

    final controller = AnimationController(vsync: this, duration: duration);
    final latTween =
        Tween<double>(begin: startCenter.latitude, end: destCenter.latitude);
    final lonTween =
        Tween<double>(begin: startCenter.longitude, end: destCenter.longitude);
    final zoomTween = Tween<double>(begin: startZoom, end: destZoom);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );

    void listener() {
      if (!mounted) return;
      _mapController.move(
        LatLng(latTween.evaluate(animation), lonTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    }

    _cameraAnimController = controller;
    _cameraAnimListener = listener;
    controller.addListener(listener);
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _stopCameraAnimation();
      }
    });
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = tokens.isRidingMode;

    final Color mapBg =
        isDark ? const Color(0xFF0B1120) : const Color(0xFFFAF9F7);
    final Color routeColor =
        isDark ? const Color(0xFF38BDF8) : const Color(0xFF2B7CE9);
    final Color casingColor =
        isDark ? const Color(0xFF0F172A) : Colors.white.withValues(alpha: 0.94);

    final LatLng originPoint = _routePoints.first;
    final LatLng destinationPoint = _routePoints.last;
    final List<Polyline> gapPolylines = _buildGapPolylines();

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCameraFit: _defaultCameraFit(context, _routePoints),
              backgroundColor: mapBg,
              minZoom: 8.5,
              maxZoom: 17.5,
              keepAlive: true,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom,
              ),
              onMapReady: () {
                _mapReady = true;
              },
            ),
            children: <Widget>[
              // 1. Zero-saveLayer real map tiles (deferred until 175ms tab slide finishes!)
              // Light Mode: OpenStreetMap + flat warm alabaster veil (0ms GPU cost vs full-screen ColorFilter saveLayer)
              // Dark Mode: Esri World Dark Gray Base + Reference labels (zero inversion shader needed)
              if (_tilesEnabled && !isDark)
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  retinaMode: false,
                  panBuffer: 0,
                  keepBuffer: 1,
                  maxNativeZoom: 19,
                  tileProvider: _tileProvider,
                  userAgentPackageName: 'com.konvoi.touring_app',
                  tileDisplay: const TileDisplay.instantaneous(),
                ),
              if (_tilesEnabled && isDark) ...<Widget>[
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
                  retinaMode: false,
                  panBuffer: 0,
                  keepBuffer: 1,
                  maxNativeZoom: 16,
                  tileProvider: _tileProvider,
                  userAgentPackageName: 'com.konvoi.touring_app',
                  tileDisplay: const TileDisplay.instantaneous(),
                ),
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
                  retinaMode: false,
                  panBuffer: 0,
                  keepBuffer: 1,
                  maxNativeZoom: 16,
                  tileProvider: _tileProvider,
                  userAgentPackageName: 'com.konvoi.touring_app',
                  tileDisplay: const TileDisplay.instantaneous(),
                ),
              ],

              // Flat GPU alpha veil softens OSM primaries into Refrensi 6.png alabaster with 0 saveLayer cost
              if (_tilesEnabled && !isDark)
                const IgnorePointer(
                  child: ColoredBox(color: Color(0x36FAF9F7)),
                ),

              // 2. Signature Refrensi 6.png Route Spline (white halo casing + Cobalt Blue GPS trace)
              PolylineLayer(
                polylines: <Polyline>[
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 8.5,
                    color: casingColor,
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 4.5,
                    color: routeColor,
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                  ...gapPolylines,
                ],
              ),

              // 3. Concentric Origin Dot + Burnt-Orange Destination Pin
              MarkerLayer(
                markers: <Marker>[
                  Marker(
                    point: originPoint,
                    width: 24,
                    height: 24,
                    child: _OriginPin(isDark: isDark),
                  ),
                  Marker(
                    point: destinationPoint,
                    width: 34,
                    height: 36,
                    alignment: const Alignment(0, -0.55),
                    child: _DestinationPin(isDark: isDark),
                  ),
                ],
              ),

              // 4. Interactive Hazard Pins anchored at real GPS coordinates
              MarkerLayer(
                markers: widget.hazardPins.map((pin) {
                  final pos = SulutRouteGeometry.pointAlongPath(
                    _routePoints,
                    pin.routeProgress,
                    lateral: pin.lateralOffset,
                  );
                  return Marker(
                    key: ValueKey<String>(pin.id),
                    point: pos,
                    width: 38,
                    height: 38,
                    child: _HazardMarker(
                      pin: pin,
                      onTap: () => widget.onTapHazard(pin),
                    ),
                  );
                }).toList(),
              ),

              // 5. Live Convoy Rider Markers riding along the actual North Sulawesi corridor
              MarkerLayer(
                markers: widget.members.map((member) {
                  final pos = SulutRouteGeometry.pointAlongPath(
                    _routePoints,
                    member.routeProgress,
                    lateral: member.lateralOffset,
                  );
                  return Marker(
                    key: ValueKey<String>(member.id),
                    point: pos,
                    width: 96,
                    height: 80,
                    alignment: const Alignment(0, -0.18),
                    child: _RiderMarker(
                      member: member,
                      isLagging: member.gapMeters > 500,
                      onTap: () => widget.onTapMember(member),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // 6. Quiet editorial attribution pill tucked cleanly in bottom-right above telemetry dock
          Positioned(
            right: 18,
            bottom: AppSpacing.floatingNavClearance + 132,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF0F172A) : Colors.white)
                      .withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '© OpenStreetMap Contributors',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Polyline> _buildGapPolylines() {
    if (!widget.hasGapAlert || widget.members.length < 2) {
      return const <Polyline>[];
    }
    final sorted = List<ConvoyMember>.from(widget.members)
      ..sort((a, b) => a.routeProgress.compareTo(b.routeProgress));
    final sweeper = sorted.first;
    final ahead = sorted[1];

    return <Polyline>[
      Polyline(
        points: <LatLng>[
          SulutRouteGeometry.pointAlongPath(
            _routePoints,
            sweeper.routeProgress,
            lateral: sweeper.lateralOffset,
          ),
          SulutRouteGeometry.pointAlongPath(
            _routePoints,
            ahead.routeProgress,
            lateral: ahead.lateralOffset,
          ),
        ],
        strokeWidth: 3.2,
        color: AppColors.accentOrangeDeep.withValues(alpha: 0.9),
        pattern: StrokePattern.dashed(segments: const <double>[8, 6]),
        strokeCap: StrokeCap.round,
      ),
    ];
  }
}

class _OriginPin extends StatelessWidget {
  const _OriginPin({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color ringColor =
        isDark ? AppColors.brandMintBright : const Color(0xFF2E43A6);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 4.5),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x2A0F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _DestinationPin extends StatelessWidget {
  const _DestinationPin({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color pinColor =
        isDark ? AppColors.ridingAccentOrange : const Color(0xFFC24515);
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Icon(
          Icons.location_on_rounded,
          color: Colors.white,
          size: 34,
          shadows: const <Shadow>[
            Shadow(
              color: Color(0x330F172A),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        Icon(
          Icons.location_on_rounded,
          color: pinColor,
          size: 30,
        ),
        const Positioned(
          top: 7,
          child: CircleAvatar(
            radius: 4.2,
            backgroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _RiderMarker extends StatelessWidget {
  const _RiderMarker({
    required this.member,
    required this.isLagging,
    required this.onTap,
  });

  final ConvoyMember member;
  final bool isLagging;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bool isYou = member.role == RiderRole.you;
    final Color ringColor = isLagging
        ? AppColors.accentOrangeDeep
        : (member.isSpeaking
            ? AppColors.brandGreenDeep
            : (isYou ? const Color(0xFF2B7CE9) : Colors.white));

    final String pillText = isLagging
        ? '${member.name} · ${member.gapMeters}m'
        : member.name;

    return Semantics(
      button: true,
      label:
          '${member.name}, ${member.role.label}, ${member.speedKmh} kilometer per jam',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 96,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Compact whisper-clean rider tag (zero crowding on map)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isLagging ? AppColors.accentOrangeDeep : tokens.surface,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: tokens.shadowColor,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  pillText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isLagging ? Colors.white : tokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              // Crisp rider avatar pin
              Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  if (isYou)
                    Container(
                      width: member.isSpeaking ? 52 : 46,
                      height: member.isSpeaking ? 52 : 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2B7CE9).withValues(
                          alpha: member.isSpeaking ? 0.24 : 0.14,
                        ),
                      ),
                    ),
                  Container(
                    width: isYou ? 38 : 34,
                    height: isYou ? 38 : 34,
                    decoration: BoxDecoration(
                      color: member.avatarColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: ringColor, width: 2.5),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: const Color(0x220F172A),
                          blurRadius: member.isSpeaking ? 10 : 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: member.isSpeaking
                        ? const Icon(
                            Icons.graphic_eq_rounded,
                            color: Colors.white,
                            size: 17,
                          )
                        : RiderAvatar(
                            size: isYou ? 33 : 29,
                            initials: member.initials,
                            fallbackColor: member.avatarColor,
                            assetPath: member.avatarAssetPath,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HazardMarker extends StatelessWidget {
  const _HazardMarker({
    required this.pin,
    required this.onTap,
  });

  final HazardPin pin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Bahaya jalan: ${pin.type.label}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: pin.type.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x2A0F172A),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(pin.type.icon, color: Colors.white, size: 19),
        ),
      ),
    );
  }
}
