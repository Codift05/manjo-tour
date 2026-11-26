import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/organic_card.dart';
import '../../core/widgets/tactile_button.dart';
import '../../state/touring_controller.dart';

/// Interactive sheet exposing live client-side Load Balancer nodes, Failover simulator,
/// LRU+TTL Memory Cache metrics, and Pagination state.
Future<void> showNetworkPerformanceSheet(BuildContext context) async {
  final controller = TouringScope.read(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NetworkPerformanceContent(controller: controller),
  );
}

class _NetworkPerformanceContent extends StatelessWidget {
  const _NetworkPerformanceContent({required this.controller});

  final TouringController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final lb = controller.loadBalancer;
        final cache = controller.cache;
        final hitPct = (cache.hitRate * 100).round();

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
                            'Performa & Load Balancer',
                            style: textTheme.headlineSmall,
                          ),
                          Text(
                            'Caching LRU+TTL, paginasi bertahap, dan failover node otomatis.',
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

                // Cache, Coalescing & Failover Telemetry Summary
                OrganicCard(
                  tone: OrganicCardTone.mint,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _StatTile(
                              value: '${cache.length}/${cache.maxEntries}',
                              label: 'Entri Cache',
                            ),
                          ),
                          Expanded(
                            child: _StatTile(
                              value: '$hitPct%',
                              label: 'Cache Hit',
                            ),
                          ),
                          Expanded(
                            child: _StatTile(
                              value: '${lb.failoverCount}',
                              label: 'Failover',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 1,
                        color: tokens.border.withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _StatTile(
                              value:
                                  '${controller.routesPage.items.length}/${controller.routesPage.totalItems}',
                              label: 'Page Rute',
                            ),
                          ),
                          Expanded(
                            child: _StatTile(
                              value:
                                  '${controller.tripsPage.items.length}/${controller.tripsPage.totalItems}',
                              label: 'Page Trip',
                            ),
                          ),
                          Expanded(
                            child: _StatTile(
                              value:
                                  '${controller.leaderboardPage.items.length}/${controller.leaderboardPage.totalItems}',
                              label: 'Page Rank',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                Text(
                  'Node Gateway Regional (Ketuk untuk uji failover)',
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                ...lb.nodes.map((node) {
                  final isActive = lb.lastServedNodeId == node.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: OrganicCard(
                      tone: node.healthy
                          ? OrganicCardTone.flat
                          : OrganicCardTone.warm,
                      borderColor: isActive && node.healthy
                          ? AppColors.brandGreenDeep
                          : null,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      onTap: () => controller.toggleBackendNodeHealth(node.id),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            node.healthy
                                ? Icons.dns_rounded
                                : Icons.cloud_off_rounded,
                            color: node.healthy
                                ? AppColors.brandGreenDeep
                                : AppColors.dangerRed,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${node.id} (${node.region})',
                                  style: textTheme.titleSmall,
                                ),
                                Text(
                                  '${node.latencyMs}ms · Bobot ${node.weight} · ${node.healthy ? (isActive ? "Aktif melayani" : "Siaga") : "Offline (Circuit Open)"}',
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: node.healthy,
                            activeTrackColor: AppColors.brandGreenDeep,
                            onChanged: (_) =>
                                controller.toggleBackendNodeHealth(node.id),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TactileButton(
                        label: 'Bersihkan Cache',
                        icon: Icons.cleaning_services_rounded,
                        variant: TactileButtonVariant.subtle,
                        onPressed: () {
                          controller.clearMemoryCache();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Memori cache dibersihkan dan halaman awal dimuat ulang.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TactileButton(
                        label: 'Selesai',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: <Widget>[
        Text(value, style: textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }
}
