import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';

enum TactileButtonVariant { primary, secondary, subtle, danger, ghost }

/// Responsive tactile button with scale(0.97) press feedback, haptic pulse,
/// visible keyboard focus outline, and glove-friendly minimum heights.
class TactileButton extends StatefulWidget {
  const TactileButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = TactileButtonVariant.primary,
    this.height = 52,
    this.expanded = false,
    this.hapticHeavy = false,
    this.padding,
    this.borderRadius,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final TactileButtonVariant variant;
  final double height;
  final bool expanded;
  final bool hapticHeavy;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _pressed = false;
  bool _focused = false;
  bool _hovered = false;

  void _triggerTap() {
    if (widget.onPressed == null) return;
    if (widget.hapticHeavy) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    widget.onPressed!.call();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bool enabled = widget.onPressed != null;
    final radius = widget.borderRadius ?? AppSpacing.buttonBorderRadius;

    Color bg;
    Color fg;
    BorderSide? border;

    switch (widget.variant) {
      case TactileButtonVariant.primary:
        bg = tokens.primaryAction;
        fg = tokens.onPrimaryAction;
      case TactileButtonVariant.secondary:
        bg = tokens.secondaryAccent;
        fg = tokens.onSecondaryAccent;
      case TactileButtonVariant.subtle:
        bg = tokens.surfaceMuted;
        fg = tokens.textPrimary;
      case TactileButtonVariant.danger:
        bg = AppColors.dangerRed;
        fg = Colors.white;
      case TactileButtonVariant.ghost:
        bg = Colors.transparent;
        fg = tokens.textPrimary;
        border = BorderSide(color: tokens.border, width: 1.5);
    }

    if (!enabled) {
      bg = tokens.surfaceMuted;
      fg = tokens.textSecondary.withValues(alpha: 0.55);
    } else if (_hovered) {
      bg = Color.alphaBlend(fg.withValues(alpha: 0.08), bg);
    }

    final Widget inner = AnimatedScale(
      scale: _pressed && enabled ? 0.96 : 1.0,
      duration: AppMotion.effective(context, const Duration(milliseconds: 80)),
      curve: Curves.easeOutCubic,
      child: Container(
        constraints: BoxConstraints(
          minHeight: widget.height,
          minWidth: widget.expanded ? double.infinity : AppSpacing.minTapTarget,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: _focused
              ? Border.all(
                  color: tokens.isRidingMode
                      ? AppColors.brandMintBright
                      : AppColors.textPrimaryLight,
                  width: 2.5,
                )
              : (border != null ? Border.fromBorderSide(border) : null),
        ),
        padding: widget.padding ??
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (widget.icon != null) ...<Widget>[
              Icon(widget.icon, size: 18, color: fg),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                widget.label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (widget.trailingIcon != null) ...<Widget>[
              const SizedBox(width: 6),
              Icon(widget.trailingIcon, size: 18, color: fg),
            ],
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        mouseCursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _triggerTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: enabled ? _triggerTap : null,
          child: inner,
        ),
      ),
    );
  }
}

/// Circular or squircle icon-only button meeting >= 48px touch target & accessible label (R-03, R-39).
class TactileIconButton extends StatefulWidget {
  const TactileIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 48,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.badgeColor,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final Color? badgeColor;
  final int badgeCount;

  @override
  State<TactileIconButton> createState() => _TactileIconButtonState();
}

class _TactileIconButtonState extends State<TactileIconButton> {
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bg = widget.backgroundColor ?? tokens.surface;
    final fg = widget.foregroundColor ?? tokens.textPrimary;

    return Semantics(
      button: true,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: FocusableActionDetector(
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          mouseCursor: widget.onPressed != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                HapticFeedback.selectionClick();
                widget.onPressed?.call();
                return null;
              },
            ),
          },
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.onPressed == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    widget.onPressed!();
                  },
            child: AnimatedScale(
              scale: _pressed ? 0.94 : 1.0,
              duration: AppMotion.effective(context, AppMotion.press),
              curve: AppMotion.easeOutStrong,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: bg,
                      shape: BoxShape.circle,
                      boxShadow: !tokens.isRidingMode && bg.a >= 0.99
                          ? <BoxShadow>[
                              BoxShadow(
                                color: tokens.shadowColor,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                      border: _focused
                          ? Border.all(color: tokens.primaryAction, width: 2.5)
                          : (widget.borderColor != null
                              ? Border.all(color: widget.borderColor!, width: 1)
                              : null),
                    ),
                    child: Icon(widget.icon, size: 22, color: fg),
                  ),
                  if (widget.badgeCount > 0)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              widget.badgeColor ?? AppColors.accentOrangeDeep,
                          shape: BoxShape.rectangle,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(999)),
                        ),
                        child: Text(
                          widget.badgeCount > 9 ? '9+' : '${widget.badgeCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
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
    );
  }
}
