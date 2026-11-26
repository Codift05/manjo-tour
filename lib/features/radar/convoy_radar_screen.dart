import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/organic_card.dart';
import '../../core/widgets/tactile_button.dart';
import '../../data/models/convoy_model.dart';
import '../../state/touring_controller.dart';
import 'widgets/convoy_map_canvas.dart';
import 'widgets/crash_sos_overlay.dart';
import 'widgets/hazard_pin_sheet.dart';
import 'widgets/walkie_talkie_overlay.dart';

/// Ultra-minimalist Live Convoy Radar screen sculpted after Refrensi 6.png ("Your Route"):
/// - Seamless single-color burnt-orange top fade (#C24515 -> 0%, matching Home) with route title + Riding Mode switch
/// - Airy borderless Origin -> Destination card with hairline inline utility strip (zero nested grey boxes)
/// - Unobstructed minimalist cartographic vector map framed cleanly between top & bottom zones
/// - Discreet vertical +/- zoom control at mid-right; Refrensi 6 concentric Recenter target right beside Jarak & Waktu
/// - Calm editorial riding dock: espresso hero PTT + refined WCAG-verified soft-tint Bahaya & SOS actions
class ConvoyRadarScreen extends StatelessWidget {
  const ConvoyRadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TouringScope.read(context);
    return ListenableBuilder(
      listenable: controller.radarNotifier,
      builder: (context, _) => _buildContent(context, controller),
    );
  }

  Widget _buildContent(BuildContext context, TouringController controller) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final route = controller.activeRoute;
    final members = controller.convoyMembers;
    final lagging = controller.laggingMember;
    final isDark = tokens.isRidingMode;
    final originLabel = route.checkpoints.isNotEmpty
        ? route.checkpoints.first.name.replaceFirst('Titik Kumpul ', '')
        : route.meetingPoint;
    final destinationLabel = route.checkpoints.isNotEmpty
        ? route.checkpoints.last.name.replaceFirst('Pos Finish ', '')
        : route.title;
    final Color topHue =
        isDark ? const Color(0xFF152033) : const Color(0xFFC24515);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // 1. Full-screen Real Interactive Sulawesi Utara Map (CartoDB + OSRM styled after Refrensi 6.png)
          ConvoyMapCanvas(
            route: route,
            members: members,
            hazardPins: controller.hazardPins,
            cameraCommand: controller.mapCameraCommand,
            cameraCommandTick: controller.mapCameraCommandTick,
            hasGapAlert: controller.hasGapAlert,
            onTapHazard: (pin) => _showHazardDetail(context, controller, pin),
            onTapMember: (member) => _showMemberQuickInfo(context, member),
          ),

          // 2. Seamless Single-Color Top Fade + Minimalist Origin->Destination Card
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Stack(
              children: <Widget>[
                // Seamless vertical opacity fade (zero hard horizontal line, matches Home)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.paddingOf(context).top + 148,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            topHue,
                            topHue,
                            topHue.withValues(alpha: 0.62),
                            topHue.withValues(alpha: 0.0),
                          ],
                          stops: const <double>[0.0, 0.46, 0.72, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // Minimal Header Title + Riding Mode Switch
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    route.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '${route.convoyCode} · ${members.length} rider · Maks ${controller.maxFormationGapMeters}m',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.labelSmall?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            TactileIconButton(
                              icon: isDark
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                              tooltip: isDark
                                  ? 'Mode Terang'
                                  : 'High-Contrast Riding Mode',
                              size: 40,
                              backgroundColor: isDark
                                  ? const Color(0xFF233047)
                                  : Colors.white.withValues(alpha: 0.18),
                              foregroundColor: Colors.white,
                              onPressed: controller.toggleRidingMode,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Airy Borderless White Origin -> Destination Card (zero nested grey boxes!)
                        RepaintBoundary(
                          child: Container(
                            decoration: BoxDecoration(
                              color: tokens.surface,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: isDark
                                      ? const Color(0x40000000)
                                      : const Color(0x142C1F1A),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 13, 14, 10),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    SizedBox(
                                      width: 20,
                                      child: Column(
                                        children: <Widget>[
                                          Container(
                                            width: 13,
                                            height: 13,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isDark
                                                    ? AppColors.brandMintBright
                                                    : const Color(0xFF2E43A6),
                                                width: 3.8,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          const _VerticalDotLine(),
                                          const SizedBox(height: 2),
                                          Icon(
                                            Icons.location_on_rounded,
                                            size: 17,
                                            color: isDark
                                                ? AppColors.ridingAccentOrange
                                                : const Color(0xFFC24515),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            originLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                textTheme.bodyMedium?.copyWith(
                                              fontSize: 13.5,
                                              color: tokens.textPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 11),
                                          Text(
                                            destinationLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                textTheme.bodyMedium?.copyWith(
                                              fontSize: 13.5,
                                              color: tokens.textPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: route.isDownloaded
                                            ? tokens.surfaceMint
                                            : tokens.surfaceMuted,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Icon(
                                            route.isDownloaded
                                                ? Icons.offline_pin_rounded
                                                : Icons.cloud_outlined,
                                            size: 13,
                                            color: route.isDownloaded
                                                ? tokens.surfaceMintInk
                                                : tokens.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            route.isDownloaded
                                                ? 'Offline'
                                                : 'Online',
                                            style:
                                                textTheme.labelSmall?.copyWith(
                                              fontSize: 11,
                                              color: route.isDownloaded
                                                  ? tokens.surfaceMintInk
                                                  : tokens.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  height: 1,
                                  color: tokens.border.withValues(alpha: 0.45),
                                ),
                                const SizedBox(height: 6),
                                // Flat hairline inline utility row (eliminates nested grey boxes)
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _InlineRouteAction(
                                        icon: controller.isSimulatingMovement
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        label: controller.isSimulatingMovement
                                            ? 'Jeda Simulasi'
                                            : 'Simulasi Jalan',
                                        active: controller.isSimulatingMovement,
                                        onTap:
                                            controller.toggleMovementSimulation,
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 16,
                                      color:
                                          tokens.border.withValues(alpha: 0.55),
                                    ),
                                    Expanded(
                                      child: _InlineRouteAction(
                                        icon: Icons.social_distance_rounded,
                                        label: controller.hasGapAlert
                                            ? 'Rapatkan Grup'
                                            : 'Uji Gap Alert',
                                        active: controller.hasGapAlert,
                                        warning: controller.hasGapAlert,
                                        onTap:
                                            controller.toggleSimulatedGapAlert,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Automatic Warm Sunset Orange Gap Alert Banner (>500m), zero saveLayer over map
                        if (lagging != null)
                          Padding(
                            key: const ValueKey<String>('gap-alert'),
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentOrange,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: tokens.shadowColor,
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.accentEspresso,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        const Text(
                                          'Gap Alert: Formasi Terpisah',
                                          style: TextStyle(
                                            color: AppColors.accentEspresso,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          '${lagging.name} (${lagging.role.label}) tertinggal ${lagging.gapMeters}m (>500m).',
                                          style: const TextStyle(
                                            color: AppColors.accentEspresso,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Active Walkie-Talkie Live Audio Visualizer Overlay
                        if (controller.isTalkingPtt)
                          Padding(
                            key: const ValueKey<String>('ptt-live'),
                            padding: const EdgeInsets.only(top: 8),
                            child: WalkieTalkieVisualizerBanner(
                              channelCode: route.convoyCode,
                              listenerCount: members.length - 1,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Discreet Minimal +/- Zoom Micro-Pill at Mid-Right (keeps bottom map open & clean)
          Positioned(
            right: 16,
            top: MediaQuery.sizeOf(context).height * 0.48,
            child: Container(
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(999),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: isDark
                        ? const Color(0x40000000)
                        : const Color(0x142C1F1A),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _MiniZoomBtn(
                    icon: Icons.add_rounded,
                    tooltip: 'Perbesar peta',
                    onTap: controller.zoomIn,
                  ),
                  Container(
                    width: 18,
                    height: 1,
                    color: tokens.border.withValues(alpha: 0.45),
                  ),
                  _MiniZoomBtn(
                    icon: Icons.remove_rounded,
                    tooltip: 'Perkecil peta',
                    onTap: controller.zoomOut,
                  ),
                ],
              ),
            ),
          ),

          // 4. Clean Refrensi 6.png Bottom Telemetry ("Jarak" / "Waktu" + Concentric Recenter) + Calm Riding Dock
          Positioned(
            left: 16,
            right: 16,
            bottom: AppSpacing.floatingNavClearance - 8,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: RepaintBoundary(
                  child: OrganicCard(
                    tone: OrganicCardTone.elevated,
                    borderRadius: BorderRadius.circular(24),
                    padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // Refrensi 6.png signature minimalist stat row: Jarak + Waktu + Concentric Recenter Target
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Jarak',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: tokens.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${route.distanceKm.toStringAsFixed(1)} km',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 28),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Waktu',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: tokens.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  route.formattedDuration,
                                  style: textTheme.titleLarge?.copyWith(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Refrensi 6.png signature concentric Recenter button right in the telemetry row
                            Semantics(
                              button: true,
                              label: 'Reset tampilan peta',
                              child: Tooltip(
                                message: 'Reset tampilan peta',
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    controller.resetZoom();
                                  },
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: tokens.surfaceMuted,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.brandMintBright
                                              : const Color(0xFF2E43A6),
                                          width: 5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Harmonious Glove-Friendly Controls (1 solid focal PTT + 2 calm WCAG-verified soft-tint actions)
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: WalkieTalkieButton(
                                isTalking: controller.isTalkingPtt,
                                onTalkingChanged: controller.setPttTalking,
                                height: 56,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _TintedRidingAction(
                              label: 'Bahaya',
                              icon: Icons.warning_amber_rounded,
                              width: 96,
                              height: 56,
                              backgroundColor: isDark
                                  ? const Color(0xFF331F12)
                                  : const Color(0xFFFCECE0),
                              foregroundColor: isDark
                                  ? const Color(0xFFFB923C)
                                  : const Color(0xFFB83B0A),
                              onPressed: () {
                                showHazardPinSheet(
                                  context: context,
                                  onSelectHazard: (hazard) {
                                    controller.addHazardPin(hazard);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Pin "${hazard.label}" dibagikan ke seluruh grup.',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _TintedRidingAction(
                              label: 'SOS',
                              width: 58,
                              height: 56,
                              backgroundColor: isDark
                                  ? const Color(0xFF36161B)
                                  : const Color(0xFFFDE8E8),
                              foregroundColor: isDark
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFFB91C1C),
                              onPressed: controller.openCrashSimulation,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 5. Full-Screen Emergency Crash Detection Overlay (when triggered)
          if (controller.isCrashAlertOpen)
            Positioned.fill(
              child: CrashSosOverlay(
                convoyCode: route.convoyCode,
                memberCount: members.length,
                sosDispatched: controller.sosDispatched,
                onCancelSafe: controller.cancelCrashAlert,
                onDispatchSos: controller.dispatchSosSignal,
              ),
            ),
        ],
      ),
    );
  }

  void _showHazardDetail(
    BuildContext context,
    TouringController controller,
    HazardPin pin,
  ) {
    final textTheme = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: pin.type.color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(pin.type.icon, color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(pin.type.label, style: textTheme.titleLarge),
                      Text(
                        'Dilaporkan ${pin.reporterName} · ${pin.timeLabel}',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(pin.note ?? pin.type.shortNote, style: textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: TactileButton(
                    label: 'Jalur Sudah Aman',
                    variant: TactileButtonVariant.subtle,
                    onPressed: () {
                      controller.removeHazardPin(pin.id);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TactileButton(
                    label: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMemberQuickInfo(BuildContext context, ConvoyMember member) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${member.name} (${member.role.label}) · ${member.bikeModel} · ${member.speedKmh} km/j · Jarak ${member.gapMeters}m',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _VerticalDotLine extends StatelessWidget {
  const _VerticalDotLine();

  @override
  Widget build(BuildContext context) {
    final color = context.tokens.textSecondary.withValues(alpha: 0.35);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(
        3,
        (_) => Container(
          width: 2,
          height: 3,
          margin: const EdgeInsets.symmetric(vertical: 1.3),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// Flat borderless inline utility toggle inside the top route card (no heavy nested grey boxes).
class _InlineRouteAction extends StatelessWidget {
  const _InlineRouteAction({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.warning = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool warning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final Color fg = active
        ? (warning
            ? AppColors.accentOrangeDeep
            : (tokens.isRidingMode
                ? AppColors.brandMintBright
                : const Color(0xFF2E43A6)))
        : tokens.textSecondary;

    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? fg : tokens.textPrimary,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w700,
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

class _MiniZoomBtn extends StatelessWidget {
  const _MiniZoomBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: tokens.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Calm soft-tint tactile riding button (WCAG AA >= 4.97:1) eliminating loud traffic-light clutter.
class _TintedRidingAction extends StatefulWidget {
  const _TintedRidingAction({
    required this.label,
    required this.width,
    required this.height,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final double width;
  final double height;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  State<_TintedRidingAction> createState() => _TintedRidingActionState();
}

class _TintedRidingActionState extends State<_TintedRidingAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.heavyImpact();
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutCubic,
          child: Container(
            width: widget.width,
            height: widget.height,
            padding: EdgeInsets.symmetric(
              horizontal: widget.icon != null ? 8 : 0,
            ),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (widget.icon != null) ...<Widget>[
                  Icon(widget.icon, size: 17, color: widget.foregroundColor),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.foregroundColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
