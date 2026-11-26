import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/mascot_badge.dart';
import '../../core/widgets/organic_card.dart';
import '../../core/widgets/tactile_button.dart';
import '../../state/touring_controller.dart';

/// Modal to start a new convoy session on any chosen route.
Future<void> showStartConvoyModal(BuildContext context) async {
  final controller = TouringScope.of(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StartConvoySheet(controller: controller),
  );
}

/// Modal to join an active convoy room by entering a route code.
Future<void> showJoinCodeModal(BuildContext context) async {
  final controller = TouringScope.of(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _JoinCodeSheet(controller: controller),
  );
}

/// Sheet listing rider notifications with mark-all-read action.
Future<void> showNotificationsModal(BuildContext context) async {
  final controller = TouringScope.of(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NotificationsSheet(controller: controller),
  );
}

class _StartConvoySheet extends StatefulWidget {
  const _StartConvoySheet({required this.controller});

  final TouringController controller;

  @override
  State<_StartConvoySheet> createState() => _StartConvoySheetState();
}

class _StartConvoySheetState extends State<_StartConvoySheet> {
  late String _selectedRouteId;
  bool _gapAlertEnabled = true;

  @override
  void initState() {
    super.initState();
    _selectedRouteId = widget.controller.activeRoute.id;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final routes = widget.controller.allRoutes;
    final selected = routes.firstWhere((r) => r.id == _selectedRouteId);

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
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
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
                const MascotArt(pose: MascotPose.ride, size: 64),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Mulai Konvoi Baru', style: textTheme.headlineSmall),
                      Text(
                        'Pilih rute dan bagikan kode ruang ke anggota grup.',
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
            const SizedBox(height: AppSpacing.lg),
            Text('Pilih Rute Konvoi', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ...routes.map((route) {
              final isSelected = route.id == _selectedRouteId;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: OrganicCard(
                  tone: isSelected
                      ? OrganicCardTone.mint
                      : OrganicCardTone.flat,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  onTap: () => setState(() => _selectedRouteId = route.id),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected
                            ? tokens.surfaceMintInk
                            : tokens.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(route.title, style: textTheme.titleSmall),
                            Text(
                              '${route.region} | ${route.distanceKm.toStringAsFixed(0)} km | ${route.formattedDuration}',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.surfaceMuted,
                          borderRadius: AppSpacing.badgeBorderRadius,
                        ),
                        child: Text(
                          route.convoyCode,
                          style: textTheme.labelSmall?.copyWith(
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.xs),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Aktifkan Gap Alert (> 500m)',
                style: textTheme.titleSmall,
              ),
              subtitle: Text(
                'Tampilkan peringatan otomatis bila Sweeper tertinggal.',
                style: textTheme.bodySmall,
              ),
              value: _gapAlertEnabled,
              activeTrackColor: AppColors.brandGreenDeep,
              onChanged: (val) => setState(() => _gapAlertEnabled = val),
            ),
            const SizedBox(height: AppSpacing.md),
            TactileButton(
              label: 'Buka Radar Konvoi (${selected.convoyCode})',
              icon: Icons.navigation_rounded,
              expanded: true,
              height: 56,
              onPressed: () {
                widget.controller.startConvoyOnRoute(selected.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Ruang konvoi ${selected.convoyCode} aktif. Selamat berkendara!',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinCodeSheet extends StatefulWidget {
  const _JoinCodeSheet({required this.controller});

  final TouringController controller;

  @override
  State<_JoinCodeSheet> createState() => _JoinCodeSheetState();
}

class _JoinCodeSheetState extends State<_JoinCodeSheet> {
  final TextEditingController _codeController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorText = 'Masukkan kode rute terlebih dahulu.');
      return;
    }
    final matched = widget.controller.joinConvoyByCode(code);
    if (matched == null) {
      setState(
        () => _errorText =
            'Kode "$code" tidak ditemukan. Coba pilih kode ruang aktif di bawah.',
      );
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Berhasil bergabung ke konvoi ${matched.title}.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                    Text('Gabung Kode Rute', style: textTheme.headlineSmall),
                    Text(
                      'Masukkan kode ruang dari Road Captain untuk masuk formasi.',
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
          const SizedBox(height: AppSpacing.lg),
          Text('Kode Ruang Konvoi', style: textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Contoh: TMH-204',
              prefixIcon: const Icon(Icons.qr_code_2_rounded),
              errorText: _errorText,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Kode simulasi yang tersedia:', style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: widget.controller.allRoutes.map((route) {
              final isPicked =
                  _codeController.text.trim().toUpperCase() == route.convoyCode;
              return Material(
                color: isPicked ? tokens.primaryAction : tokens.surfaceMuted,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    setState(() {
                      _codeController.text = route.convoyCode;
                      _errorText = null;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Text(
                      '${route.convoyCode} (${route.category.label})',
                      style: textTheme.labelMedium?.copyWith(
                        color: isPicked
                            ? tokens.onPrimaryAction
                            : tokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          TactileButton(
            label: 'Gabung ke Radar Konvoi',
            icon: Icons.groups_rounded,
            variant: TactileButtonVariant.secondary,
            expanded: true,
            height: 56,
            onPressed: _submit,
          ),
        ],
        ),
      ),
    );
  }
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet({required this.controller});

  final TouringController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: controller.homeNotifier,
      builder: (context, _) {
        final items = controller.notifications;
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
                    child: Text('Notifikasi Konvoi', style: textTheme.headlineSmall),
                  ),
                  if (controller.unreadNotificationCount > 0)
                    TextButton(
                      onPressed: controller.markAllNotificationsRead,
                      child: const Text('Tandai dibaca'),
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
              ...items.map((n) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: OrganicCard(
                    tone: n.unread
                        ? OrganicCardTone.mint
                        : OrganicCardTone.flat,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: tokens.surface,
                            borderRadius: AppSpacing.badgeBorderRadius,
                          ),
                          child: Icon(
                            n.icon,
                            size: 20,
                            color: n.unread
                                ? tokens.surfaceMintInk
                                : tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: textTheme.titleSmall,
                                    ),
                                  ),
                                  Text(n.timeLabel, style: textTheme.bodySmall),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(n.body, style: textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
            ),
          ),
        );
      },
    );
  }
}
