import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/mascot_badge.dart';

/// Glove-friendly Push-to-Talk (Walkie-Talkie) button (64px height).
class WalkieTalkieButton extends StatefulWidget {
  const WalkieTalkieButton({
    super.key,
    required this.isTalking,
    required this.onTalkingChanged,
    this.height = 56,
  });

  final bool isTalking;
  final ValueChanged<bool> onTalkingChanged;
  final double height;

  @override
  State<WalkieTalkieButton> createState() => _WalkieTalkieButtonState();
}

class _WalkieTalkieButtonState extends State<WalkieTalkieButton> {
  void _startTalking() {
    if (!widget.isTalking) {
      HapticFeedback.heavyImpact();
      widget.onTalkingChanged(true);
    }
  }

  void _stopTalking() {
    if (widget.isTalking) {
      HapticFeedback.lightImpact();
      widget.onTalkingChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final talking = widget.isTalking;

    return Semantics(
      button: true,
      label: talking
          ? 'Sedang berbicara ke seluruh grup konvoi. Lepas untuk berhenti.'
          : 'Tahan untuk bicara melalui Walkie-Talkie konvoi',
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTalkingChanged(!talking);
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _startTalking(),
          onTapUp: (_) => _stopTalking(),
          onTapCancel: _stopTalking,
          child: AnimatedScale(
            scale: talking ? 0.96 : 1.0,
            duration: AppMotion.effective(context, AppMotion.press),
            curve: AppMotion.easeOutStrong,
            child: AnimatedContainer(
              duration: AppMotion.effective(context, AppMotion.fast),
              curve: AppMotion.easeOutStrong,
              height: widget.height,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: talking
                    ? AppColors.brandGreenDeep
                    : tokens.primaryAction,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: talking
                      ? AppColors.brandMintBright
                      : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: talking
                    ? <BoxShadow>[
                        BoxShadow(
                          color: AppColors.brandGreen.withValues(alpha: 0.45),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    talking ? Icons.mic_rounded : Icons.mic_none_rounded,
                    size: 20,
                    color: talking ? Colors.white : tokens.onPrimaryAction,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          talking ? 'MENGIRIM...' : 'Tahan Bicara (HT)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: talking
                                ? Colors.white
                                : tokens.onPrimaryAction,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          talking ? 'Lepas selesai' : 'Saluran Aktif',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: (talking
                                    ? Colors.white
                                    : tokens.onPrimaryAction)
                                .withValues(alpha: 0.85),
                            fontSize: 10.5,
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
        ),
      ),
    );
  }
}

/// Live Push-to-Talk overlay pairing animated Panda Walkie-Talkie WebP
/// with our lightweight Lottie soundwave equalizer (shown ONLY while held, R-19).
class WalkieTalkieVisualizerBanner extends StatelessWidget {
  const WalkieTalkieVisualizerBanner({
    super.key,
    required this.channelCode,
    required this.listenerCount,
  });

  final String channelCode;
  final int listenerCount;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduceMotion(context);

    return Semantics(
      liveRegion: true,
      label:
          'Walkie-Talkie aktif ke $listenerCount anggota saluran $channelCode',
      child: RepaintBoundary(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.brandGreenDeep,
            borderRadius: AppSpacing.cardBorderRadius,
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x3D0F172A),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              const MascotArt(
                pose: MascotPose.ptt,
                size: 56,
                semanticLabel: 'Panda berbicara melalui Walkie-Talkie',
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Siaran Suara Grup Aktif',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Saluran $channelCode | $listenerCount rider mendengarkan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              SizedBox(
                width: 60,
                height: 40,
                child: Lottie.asset(
                  'assets/animations/lottie_soundwave.json',
                  animate: !reduceMotion,
                  repeat: true,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
