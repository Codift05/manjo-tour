import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';

class NavDestination {
  const NavDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.showActiveDot = false,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool showActiveDot;
}

/// Minimalist capsule Floating Bottom Navigation Bar matching Refrensi 4.png:
/// soft light capsule with a warm dark solid circular indicator gliding smoothly between icons.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.destinations,
    required this.onSelected,
  });

  final int currentIndex;
  final List<NavDestination> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final int count = destinations.length;

    // Warm deep espresso-charcoal circle matching the uploaded navbar reference
    final Color indicatorColor = tokens.isRidingMode
        ? AppColors.brandMintBright
        : const Color(0xFF2B2320);
    final Color activeIconColor =
        tokens.isRidingMode ? AppColors.backgroundRiding : Colors.white;
    final Color inactiveIconColor =
        tokens.isRidingMode ? tokens.textSecondary : const Color(0xFF6B726E);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        bottomInset > 0 ? bottomInset + 6 : AppSpacing.md,
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: RepaintBoundary(
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: tokens.isRidingMode ? tokens.surface : Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: tokens.shadowColor,
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double slotWidth = constraints.maxWidth / count;
                  const double bubbleSize = 52;
                  final double targetLeft = (slotWidth * currentIndex) +
                      (slotWidth - bubbleSize) / 2;

                  return Stack(
                    alignment: Alignment.centerLeft,
                    children: <Widget>[
                      // Compositor-only translate synced to AppShell's 175ms easeOutCubic slide
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: targetLeft),
                        duration: AppMotion.effective(
                          context,
                          const Duration(milliseconds: 175),
                        ),
                        curve: Curves.easeOutCubic,
                        builder: (context, dx, child) {
                          return Transform.translate(
                            offset: Offset(dx, 0),
                            child: child,
                          );
                        },
                        child: SizedBox(
                          width: bubbleSize,
                          height: bubbleSize,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: indicatorColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: List<Widget>.generate(count, (index) {
                          final item = destinations[index];
                          final selected = index == currentIndex;

                          return Expanded(
                            child: _CircularNavSlot(
                              destination: item,
                              selected: selected,
                              activeIconColor: activeIconColor,
                              inactiveIconColor: inactiveIconColor,
                              onTap: () {
                                if (index != currentIndex) {
                                  HapticFeedback.selectionClick();
                                  onSelected(index);
                                }
                              },
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircularNavSlot extends StatefulWidget {
  const _CircularNavSlot({
    required this.destination,
    required this.selected,
    required this.activeIconColor,
    required this.inactiveIconColor,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final Color activeIconColor;
  final Color inactiveIconColor;
  final VoidCallback onTap;

  @override
  State<_CircularNavSlot> createState() => _CircularNavSlotState();
}

class _CircularNavSlotState extends State<_CircularNavSlot> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      selected: widget.selected,
      button: true,
      label: widget.destination.label,
      child: Tooltip(
        message: widget.destination.label,
        child: FocusableActionDetector(
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          mouseCursor: SystemMouseCursors.click,
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: _focused
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: tokens.primaryAction,
                          width: 2,
                        ),
                      )
                    : null,
                alignment: Alignment.center,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Icon(
                      widget.selected
                          ? widget.destination.activeIcon
                          : widget.destination.icon,
                      size: 24,
                      color: widget.selected
                          ? widget.activeIconColor
                          : widget.inactiveIconColor,
                    ),
                    if (widget.destination.showActiveDot && !widget.selected)
                      Positioned(
                        right: -3,
                        top: -2,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AppColors.accentOrangeDeep,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: tokens.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
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
