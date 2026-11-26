import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/mascot_badge.dart';
import '../../../core/widgets/tactile_button.dart';

/// Full-screen Phone-Based Crash Detection Simulation Overlay (PRD Pilar 2):
/// 10-second countdown with giant glove-friendly "Saya Baik-Baik Saja" cancel control
/// or automatic SOS coordinate broadcast to all convoy members.
class CrashSosOverlay extends StatefulWidget {
  const CrashSosOverlay({
    super.key,
    required this.convoyCode,
    required this.memberCount,
    required this.sosDispatched,
    required this.onCancelSafe,
    required this.onDispatchSos,
  });

  final String convoyCode;
  final int memberCount;
  final bool sosDispatched;
  final VoidCallback onCancelSafe;
  final VoidCallback onDispatchSos;

  @override
  State<CrashSosOverlay> createState() => _CrashSosOverlayState();
}

class _CrashSosOverlayState extends State<CrashSosOverlay> {
  static const int _initialSeconds = 10;
  int _secondsLeft = _initialSeconds;
  Timer? _timer;
  double _slideValue = 0.0;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    if (!widget.sosDispatched) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
        HapticFeedback.heavyImpact();
        widget.onDispatchSos();
      } else {
        HapticFeedback.mediumImpact();
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sent = widget.sosDispatched;

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              widget.onCancelSafe();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Material(
            color: AppColors.backgroundRiding.withValues(alpha: 0.96),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    // Top status pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sent
                            ? AppColors.dangerRed
                            : AppColors.accentOrangeDeep,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            sent
                                ? Icons.sos_rounded
                                : Icons.sensors_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              sent
                                  ? 'SINYAL SOS TERKIRIM'
                                  : 'DETEKSI BENTURAN',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Center Countdown or Confirmation
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (!sent) ...<Widget>[
                          SizedBox(
                            width: 176,
                            height: 176,
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                SizedBox(
                                  width: 176,
                                  height: 176,
                                  child: CircularProgressIndicator(
                                    value: _secondsLeft / _initialSeconds,
                                    strokeWidth: 12,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.14),
                                    color: AppColors.ridingAccentOrange,
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      '$_secondsLeft',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 56,
                                        fontWeight: FontWeight.w800,
                                        height: 1.0,
                                      ),
                                    ),
                                    const Text(
                                      'detik',
                                      style: TextStyle(
                                        color: AppColors.textSecondaryRiding,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Apakah kamu baik-baik saja?',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Sensor mendeteksi hentakan keras. Jika tidak dibatalkan, sinyal SOS dan koordinat GPS (1.3236, 124.8389) akan dikirim otomatis ke ${widget.memberCount} anggota konvoi ${widget.convoyCode}.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondaryRiding,
                            ),
                          ),
                        ] else ...<Widget>[
                          const MascotArt(
                            pose: MascotPose.alert,
                            size: 108,
                            semanticLabel: 'Sinyal SOS aktif',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'SOS & Koordinat Terkirim!',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Leader (Dimas) dan Sweeper (Bagas) telah menerima lokasi daruratmu di 1.3236, 124.8389 beserta status baterai.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondaryRiding,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Bottom Giant Glove-Friendly Controls (64px+)
                    Column(
                      children: <Widget>[
                        if (!sent) ...<Widget>[
                          // Slide-to-confirm safe bar
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceRiding,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.brandMintBright,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: <Widget>[
                                const Text(
                                  'Geser penuh ke kanan untuk batalkan SOS',
                                  style: TextStyle(
                                    color: AppColors.textSecondaryRiding,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 10,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 16,
                                    ),
                                    activeTrackColor: AppColors.brandMintBright,
                                    inactiveTrackColor: AppColors.borderRiding,
                                    thumbColor: AppColors.brandMintBright,
                                  ),
                                  child: Slider(
                                    value: _slideValue,
                                    onChanged: (val) {
                                      setState(() => _slideValue = val);
                                      if (val >= 0.92) {
                                        _timer?.cancel();
                                        HapticFeedback.mediumImpact();
                                        widget.onCancelSafe();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          // Direct giant 64px safe button (for one-tap glove accessibility)
                          TactileButton(
                            label: 'Saya Baik-Baik Saja (Batalkan)',
                            icon: Icons.check_circle_rounded,
                            variant: TactileButtonVariant.primary,
                            height: 64,
                            expanded: true,
                            hapticHeavy: true,
                            onPressed: () {
                              _timer?.cancel();
                              widget.onCancelSafe();
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TactileButton(
                            label: 'Kirim SOS Sekarang',
                            icon: Icons.sos_rounded,
                            variant: TactileButtonVariant.danger,
                            height: 56,
                            expanded: true,
                            hapticHeavy: true,
                            onPressed: () {
                              _timer?.cancel();
                              setState(() => _secondsLeft = 0);
                              widget.onDispatchSos();
                            },
                          ),
                        ] else ...<Widget>[
                          TactileButton(
                            label: 'Saya Sudah Aman, Tutup SOS',
                            icon: Icons.check_circle_rounded,
                            variant: TactileButtonVariant.primary,
                            height: 64,
                            expanded: true,
                            hapticHeavy: true,
                            onPressed: widget.onCancelSafe,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
