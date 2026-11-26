import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/organic_card.dart';
import '../../../core/widgets/tactile_button.dart';
import '../../../data/models/convoy_model.dart';

/// Quick-Tap 1-touch Hazard Pinning Sheet (PRD Pilar 2):
/// Jalan Berlubang, Jalan Licin/Hujan, Macet/Longsor, Butuh Bensin/Trouble.
/// Large glove-friendly buttons (>=64px) for safe road reporting.
Future<void> showHazardPinSheet({
  required BuildContext context,
  required ValueChanged<HazardType> onSelectHazard,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final tokens = context.tokens;
      final textTheme = Theme.of(context).textTheme;

      return Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Tandai Bahaya Jalan (1 Sentuhan)',
                        style: textTheme.headlineSmall,
                      ),
                      Text(
                        'Pin langsung muncul di peta seluruh anggota konvoi.',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TactileIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Tutup',
                  size: 44,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.25,
              children: HazardType.values.map((hazard) {
                return OrganicCard(
                  tone: OrganicCardTone.muted,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    onSelectHazard(hazard);
                    Navigator.of(context).pop();
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: hazard.color,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(hazard.icon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: Text(
                          hazard.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        ),
      );
    },
  );
}
