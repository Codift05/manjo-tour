import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/mascot_badge.dart';
import '../../core/widgets/tactile_button.dart';
import '../../data/models/profile_model.dart';

Future<void> showPatchDetailDialog(
  BuildContext context,
  DigitalPatch patch,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      final tokens = context.tokens;
      final textTheme = Theme.of(context).textTheme;
      final pct = (patch.progress * 100).round();
      final reduceMotion = AppMotion.reduceMotion(context);

      return Dialog(
        backgroundColor: tokens.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.cardBorderRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 144,
                height: 144,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    if (patch.unlocked && !reduceMotion)
                      Lottie.asset(
                        'assets/animations/lottie_confetti_burst.json',
                        repeat: false,
                        width: 144,
                        height: 144,
                      ),
                    if (patch.unlocked)
                      const MascotArt(
                        pose: MascotPose.celebrate,
                        size: 112,
                        semanticLabel: 'Selebrasi lencana terbuka',
                      )
                    else
                      Image.asset(
                        patch.patchAssetPath,
                        width: 108,
                        height: 108,
                        cacheWidth: 216,
                        fit: BoxFit.contain,
                        color: const Color(0xB8FFFFFF),
                        colorBlendMode: BlendMode.modulate,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: patch.unlocked
                      ? AppColors.brandGreenDeep
                      : tokens.surfaceMuted,
                  borderRadius: AppSpacing.badgeBorderRadius,
                ),
                child: Text(
                  patch.unlocked ? 'Lencana Terbuka' : 'Progres $pct%',
                  style: textTheme.labelSmall?.copyWith(
                    color: patch.unlocked ? Colors.white : tokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                patch.title,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                patch.requirement,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: patch.progress,
                  minHeight: 8,
                  backgroundColor: tokens.surfaceMuted,
                  color: patch.unlocked
                      ? AppColors.brandGreenDeep
                      : AppColors.accentOrangeDeep,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TactileButton(
                label: 'Tutup',
                expanded: true,
                variant: TactileButtonVariant.subtle,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}
