import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/directional_slide_switcher.dart';
import '../../core/widgets/organic_card.dart';
import '../../core/widgets/rider_avatar.dart';
import '../../core/widgets/scenic_illustrations.dart';
import '../../core/widgets/tactile_button.dart';
import '../../data/models/trip_model.dart';
import '../../state/touring_controller.dart';
import 'trips_screen.dart';

/// Minimalist Trip Detail screen unified with Beranda, Radar, Perjalanan & Profil:
/// - Seamless single-color burnt-orange top vertical fade (#C24515 -> 0%, zero abrupt sheet cutout)
/// - Borderless translucent glass back button + compact espresso "Buka Radar" pill
/// - Compositor-animated white capsule segmented switcher (espresso #2B2320 sliding pill)
/// - Clean borderless Split-Bill summary (zero nested box-in-box), soft-tint Lunas/Belum pills,
///   clean Checkpoints checklist & RiderAvatar Participants list
class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({
    super.key,
    required this.tripId,
  });

  final String tripId;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  static const int _expensePageSize = 4;

  int _selectedSection = 0; // 0 = Split-Bill, 1 = Checkpoint, 2 = Peserta
  int _visibleExpenses = _expensePageSize;

  @override
  Widget build(BuildContext context) {
    final controller = TouringScope.read(context);
    return ListenableBuilder(
      listenable: controller.tripsNotifier,
      builder: (context, _) => _buildContent(context, controller),
    );
  }

  Widget _buildContent(BuildContext context, TouringController controller) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final isDark = tokens.isRidingMode;
    final trip = controller.findTrip(widget.tripId);

    if (trip == null) {
      return Scaffold(
        backgroundColor: tokens.canvas,
        appBar: AppBar(title: const Text('Perjalanan')),
        body: const Center(child: Text('Perjalanan tidak ditemukan.')),
      );
    }

    final Color topHue =
        isDark ? const Color(0xFF152033) : const Color(0xFFC24515);
    final String cleanDate = trip.dateLabel.replaceFirst(' (Aktif)', '');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: tokens.canvas,
        resizeToAvoidBottomInset: false,
        body: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: <Widget>[
            // 1. Scenic 2D WebP Landscape Header + Seamless Warm Burnt-Orange Mist Fade into Canvas
            SliverToBoxAdapter(
              child: Stack(
                children: <Widget>[
                  // Vibrant 2D route landscape illustration (clearly visible at top!)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 24,
                    child: RepaintBoundary(
                      child: ScenicIllustration(
                        variant: trip.scenicVariant,
                        height: 290,
                      ),
                    ),
                  ),

                  // Soft top status-bar scrim + warm burnt-orange sunset mist behind title -> seamless fade into canvas
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              (isDark
                                      ? const Color(0xFF0B1120)
                                      : const Color(0xFF4A1806))
                                  .withValues(alpha: 0.34),
                              Colors.transparent,
                              topHue.withValues(alpha: 0.0),
                              topHue.withValues(alpha: 0.90),
                              topHue.withValues(alpha: 0.92),
                              tokens.canvas,
                            ],
                            stops: const <double>[
                              0.0,
                              0.22,
                              0.40,
                              0.64,
                              0.78,
                              0.96,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              TactileIconButton(
                                icon: Icons.arrow_back_rounded,
                                tooltip: 'Kembali',
                                size: 42,
                                backgroundColor: isDark
                                    ? const Color(0xCC182235)
                                    : Colors.white.withValues(alpha: 0.90),
                                foregroundColor: isDark
                                    ? Colors.white
                                    : AppColors.textPrimaryLight,
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              TactileButton(
                                label: 'Buka Radar',
                                icon: Icons.radar_rounded,
                                height: 40,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                borderRadius: BorderRadius.circular(999),
                                onPressed: () {
                                  controller.startConvoyOnRoute(trip.routeId);
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                          // Breathing window so the 2D landscape illustration shines clearly
                          const SizedBox(height: 82),
                          Text(
                            trip.title,
                            style: textTheme.displaySmall?.copyWith(
                              fontSize: 25,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${trip.region} · $cleanDate · ${trip.convoyCode}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.94),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Unified Borderless White Capsule Segmented Tabs (mirrors FloatingNavBar!)
                          _SlidingSegmentedTabs(
                            selectedIndex: _selectedSection,
                            labels: <String>[
                              'Split-Bill',
                              'Checkpoint',
                              'Peserta (${trip.participants.length})',
                            ],
                            onChanged: (idx) =>
                                setState(() => _selectedSection = idx),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Non-overlapping edge-to-edge GPU Horizontal Slide Section Content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 40),
              sliver: SliverToBoxAdapter(
                child: DirectionalSlideSwitcher(
                  index: _selectedSection,
                  duration: const Duration(milliseconds: 180),
                  backgroundColor: tokens.canvas,
                  child: KeyedSubtree(
                    key: ValueKey<int>(_selectedSection),
                    child: switch (_selectedSection) {
                      0 => _SplitBillSection(
                          trip: trip,
                          visibleExpenseCount: _visibleExpenses,
                          onLoadMoreExpenses: () => setState(
                            () => _visibleExpenses += _expensePageSize,
                          ),
                          onAddExpense: () => _showAddExpenseSheet(
                            context,
                            controller,
                            trip,
                          ),
                          onTogglePaid: (expenseId, memberId) {
                            HapticFeedback.selectionClick();
                            controller.toggleExpenseMemberPaid(
                              trip.id,
                              expenseId,
                              memberId,
                            );
                          },
                        ),
                      1 => _CheckpointsSection(
                          trip: trip,
                          onToggle: (idx) {
                            HapticFeedback.selectionClick();
                            controller.toggleCheckpointCompleted(
                              trip.id,
                              idx,
                            );
                          },
                        ),
                      _ => _ParticipantsSection(trip: trip),
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddExpenseSheet(
    BuildContext context,
    TouringController controller,
    TouringTrip trip,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddExpenseSheet(
        trip: trip,
        onSubmit: (title, category, amount, paidById) {
          controller.addTripExpense(
            tripId: trip.id,
            title: title,
            category: category,
            amountIdr: amount,
            paidById: paidById,
          );
        },
      ),
    );
  }
}

/// Borderless white capsule segmented control matching FloatingNavBar's sliding dark pill.
/// Uses compositor-only Transform.translate for 0 relayouts per frame.
class _SlidingSegmentedTabs extends StatelessWidget {
  const _SlidingSegmentedTabs({
    required this.selectedIndex,
    required this.labels,
    required this.onChanged,
  });

  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final Color activeBg = tokens.isRidingMode
        ? AppColors.brandMintBright
        : const Color(0xFF2B2320);
    final Color activeFg =
        tokens.isRidingMode ? AppColors.backgroundRiding : Colors.white;

    return Container(
      height: 50,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: tokens.isRidingMode ? tokens.surface : Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: !tokens.isRidingMode
            ? <BoxShadow>[
                BoxShadow(
                  color: tokens.shadowColor,
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double tabWidth = constraints.maxWidth / labels.length;
          return Stack(
            children: <Widget>[
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: tabWidth * selectedIndex),
                duration: AppMotion.effective(
                  context,
                  const Duration(milliseconds: 180),
                ),
                curve: Curves.easeOutCubic,
                builder: (context, dx, child) => Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                ),
                child: SizedBox(
                  width: tabWidth,
                  height: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: activeBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Row(
                children: List<Widget>.generate(labels.length, (i) {
                  final selected = i == selectedIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (i != selectedIndex) {
                          HapticFeedback.selectionClick();
                          onChanged(i);
                        }
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: AppMotion.effective(
                            context,
                            const Duration(milliseconds: 140),
                          ),
                          style: (textTheme.labelMedium ?? const TextStyle())
                              .copyWith(
                            fontSize: 13,
                            color: selected ? activeFg : tokens.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                          ),
                          child: Text(
                            labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SplitBillSection extends StatelessWidget {
  const _SplitBillSection({
    required this.trip,
    required this.visibleExpenseCount,
    required this.onLoadMoreExpenses,
    required this.onAddExpense,
    required this.onTogglePaid,
  });

  final TouringTrip trip;
  final int visibleExpenseCount;
  final VoidCallback onLoadMoreExpenses;
  final VoidCallback onAddExpense;
  final void Function(String expenseId, String memberId) onTogglePaid;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final isDark = tokens.isRidingMode;
    final visibleExpenses = trip.expenses.take(visibleExpenseCount).toList();
    final hasMoreExpenses = visibleExpenses.length < trip.expenses.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Clean Borderless White Summary Card (eliminates nested box-inside-box!)
        OrganicCard(
          tone: OrganicCardTone.elevated,
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Total Pengeluaran Grup',
                          style: textTheme.labelMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          formatRupiah(trip.totalExpenseIdr),
                          style: textTheme.headlineMedium?.copyWith(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text('Per Rider', style: textTheme.labelSmall),
                      const SizedBox(height: 2),
                      Text(
                        formatRupiah(trip.perRiderTotalIdr),
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.ridingAccentOrange
                              : const Color(0xFFC24515),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TactileButton(
                label: 'Catat Pengeluaran Baru',
                icon: Icons.add_rounded,
                expanded: true,
                height: 48,
                borderRadius: BorderRadius.circular(999),
                onPressed: onAddExpense,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        Text(
          'Rincian Patungan (${trip.expenses.length})',
          style: textTheme.headlineSmall?.copyWith(
            fontSize: 18.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Ketuk nama anggota untuk mengubah status Lunas atau Belum Bayar.',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: 12),

        ...visibleExpenses.map((expense) {
          final payer = trip.participants.firstWhere(
            (p) => p.id == expense.paidById,
            orElse: () => trip.participants.first,
          );

          return RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OrganicCard(
              tone: OrganicCardTone.elevated,
              borderRadius: BorderRadius.circular(22),
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: expense.category.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          expense.category.icon,
                          color: expense.category.color,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              expense.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Dibayar ${payer.name.split(' ').first} · ${expense.timeLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            formatRupiah(expense.amountIdr),
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${formatRupiah(expense.perMemberShare)}/org',
                            style: textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? AppColors.ridingAccentOrange
                                  : AppColors.accentAmber,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: tokens.border.withValues(alpha: 0.45),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: trip.participants.map((member) {
                      final isPaid =
                          expense.paidStatusByMemberId[member.id] ?? false;
                      final Color chipBg = isPaid
                          ? (isDark
                              ? const Color(0xFF133A2C)
                              : const Color(0xFFE5F5EC))
                          : (isDark
                              ? const Color(0xFF331F12)
                              : const Color(0xFFFCECE0));
                      final Color chipFg = isPaid
                          ? (isDark
                              ? AppColors.brandMintBright
                              : const Color(0xFF14693E))
                          : (isDark
                              ? AppColors.ridingAccentOrange
                              : const Color(0xFFB83B0A));

                      return Semantics(
                        button: true,
                        label:
                            '${member.name}: ${isPaid ? "Lunas" : "Belum Bayar"}',
                        child: GestureDetector(
                          onTap: () => onTogglePaid(expense.id, member.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  isPaid
                                      ? Icons.check_circle_rounded
                                      : Icons.schedule_rounded,
                                  size: 14,
                                  color: chipFg,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${member.name.split(' ').first}: ${isPaid ? "Lunas" : "Belum"}',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: chipFg,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            ),
          );
        }),
        if (hasMoreExpenses)
          OrganicCard(
            tone: OrganicCardTone.elevated,
            borderRadius: BorderRadius.circular(999),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            onTap: onLoadMoreExpenses,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: tokens.textPrimary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Lihat ${trip.expenses.length - visibleExpenses.length} Pengeluaran Lainnya',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CheckpointsSection extends StatelessWidget {
  const _CheckpointsSection({
    required this.trip,
    required this.onToggle,
  });

  final TouringTrip trip;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Ketuk checkpoint untuk menandai pos yang sudah dilewati.',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        ...List<Widget>.generate(trip.checkpoints.length, (i) {
          final cp = trip.checkpoints[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OrganicCard(
              tone: OrganicCardTone.elevated,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.all(14),
              onTap: () => onToggle(i),
              child: Row(
                children: <Widget>[
                  Icon(
                    cp.completed
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 22,
                    color: cp.completed
                        ? AppColors.brandGreenDeep
                        : tokens.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          cp.name,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${cp.type} · KM ${cp.kmMark.toStringAsFixed(1)} · ${cp.note}',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ParticipantsSection extends StatelessWidget {
  const _ParticipantsSection({required this.trip});

  final TouringTrip trip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.tokens;
    final isDark = tokens.isRidingMode;

    return Column(
      children: trip.participants.map((p) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OrganicCard(
            tone: OrganicCardTone.elevated,
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                RiderAvatar(
                  size: 44,
                  initials: p.initials,
                  fallbackColor: p.avatarColor,
                  assetPath: p.avatarAssetPath,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        p.name,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(p.bikeModel, style: textTheme.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF331F12)
                        : const Color(0xFFFCECE0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    p.roleLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.ridingAccentOrange
                          : const Color(0xFFB83B0A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet({
    required this.trip,
    required this.onSubmit,
  });

  final TouringTrip trip;
  final void Function(
    String title,
    ExpenseCategory category,
    int amount,
    String paidById,
  ) onSubmit;

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.fuel;
  late String _paidById;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _paidById = widget.trip.participants.first.id;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(digits) ?? 0;

    if (title.isEmpty) {
      setState(() => _errorMessage = 'Isi nama pengeluaran terlebih dahulu.');
      return;
    }
    if (amount < 1000) {
      setState(() => _errorMessage = 'Masukkan nominal minimal Rp1.000.');
      return;
    }
    widget.onSubmit(title, _category, amount, _paidById);
    Navigator.of(context).pop();
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
                  child: Text(
                    'Catat Pengeluaran Grup',
                    style: textTheme.headlineSmall,
                  ),
                ),
                TactileIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Tutup',
                  size: 42,
                  backgroundColor: tokens.surfaceMuted,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Kategori', style: textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExpenseCategory.values.map((cat) {
                final selected = _category == cat;
                return _SheetChoicePill(
                  label: cat.label,
                  icon: cat.icon,
                  selected: selected,
                  onTap: () => setState(() => _category = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Keterangan Pengeluaran', style: textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Contoh: Isi bensin SPBU Winangun',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Total Nominal (Rupiah)', style: textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'Contoh: 160000',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Dibayar Oleh', style: textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.trip.participants.map((p) {
                return _SheetChoicePill(
                  label: p.name.split(' ').first,
                  selected: _paidById == p.id,
                  onTap: () => setState(() => _paidById = p.id),
                );
              }).toList(),
            ),
            if (_errorMessage != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage!,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.dangerRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            TactileButton(
              label:
                  'Simpan & Bagi Rata (${widget.trip.participants.length} Rider)',
              icon: Icons.check_rounded,
              expanded: true,
              height: 52,
              borderRadius: BorderRadius.circular(999),
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetChoicePill extends StatelessWidget {
  const _SheetChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final Color activeBg = tokens.isRidingMode
        ? AppColors.brandMintBright
        : const Color(0xFF2B2320);
    final Color activeFg =
        tokens.isRidingMode ? AppColors.backgroundRiding : Colors.white;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? activeBg : tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  size: 15,
                  color: selected ? activeFg : tokens.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? activeFg : tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
