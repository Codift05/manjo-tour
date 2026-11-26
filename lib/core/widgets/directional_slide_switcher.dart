import 'package:flutter/material.dart';
import '../theme/app_motion.dart';

/// Pure GPU non-overlapping directional horizontal slide switcher (zero FadeTransition/saveLayer).
/// Uses a dedicated AnimationController so both incoming and outgoing slides are always computed
/// from the active navigation direction (never frozen from an old entry tween), backed by an opaque
/// canvas color so elements never collide, overlap, or pop out of order.
class DirectionalSlideSwitcher extends StatefulWidget {
  const DirectionalSlideSwitcher({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 180),
    this.slideFraction = 1.0,
    this.backgroundColor,
  });

  final int index;
  final Widget child;
  final Duration duration;
  final double slideFraction;
  final Color? backgroundColor;

  @override
  State<DirectionalSlideSwitcher> createState() =>
      _DirectionalSlideSwitcherState();
}

class _DirectionalSlideSwitcherState extends State<DirectionalSlideSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late CurvedAnimation _curvedAnimation;
  late int _currentIndex;
  late Widget _currentChild;
  Widget? _outgoingChild;
  int _direction = 1; // 1 = forward (incoming from right), -1 = backward (from left)

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _currentChild = widget.child;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1.0,
    );
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.addStatusListener(_onAnimationStatus);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        mounted &&
        _outgoingChild != null) {
      setState(() {
        _outgoingChild = null;
      });
    }
  }

  @override
  void didUpdateWidget(covariant DirectionalSlideSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }

    if (widget.index != _currentIndex) {
      final bool reduce = AppMotion.reduceMotion(context) ||
          widget.duration == Duration.zero;
      _direction = widget.index > _currentIndex ? 1 : -1;
      _currentIndex = widget.index;

      if (reduce) {
        _outgoingChild = null;
        _currentChild = widget.child;
        _controller.value = 1.0;
      } else {
        _outgoingChild = _currentChild;
        _currentChild = widget.child;
        _controller.forward(from: 0.0);
      }
    } else {
      // Data update on the same tab/section: update child without re-sliding.
      _currentChild = widget.child;
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _curvedAnimation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.isAnimating ||
        _outgoingChild == null ||
        AppMotion.reduceMotion(context)) {
      return _currentChild;
    }

    final Color bgColor =
        widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;
    final Animation<Offset> incomingSlide = Tween<Offset>(
      begin: Offset(_direction * widget.slideFraction, 0),
      end: Offset.zero,
    ).animate(_curvedAnimation);
    final Animation<Offset> outgoingSlide = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-_direction * widget.slideFraction, 0),
    ).animate(_curvedAnimation);

    return ClipRect(
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          // Incoming drives container height immediately without vertical jump.
          SlideTransition(
            position: incomingSlide,
            child: RepaintBoundary(
              child: ColoredBox(
                color: bgColor,
                child: SizedBox(
                  width: double.infinity,
                  child: _currentChild,
                ),
              ),
            ),
          ),
          // Outgoing slides cleanly edge-to-edge on top of its own opaque backing.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: TickerMode(
                enabled: false,
                child: SlideTransition(
                  position: outgoingSlide,
                  child: RepaintBoundary(
                    child: ColoredBox(
                      color: bgColor,
                      child: SizedBox(
                        width: double.infinity,
                        child: _outgoingChild,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom crisp horizontal slide route for pushing detail screens (zero full-screen Opacity saveLayer).
class KonvoiSlidePageRoute<T> extends PageRouteBuilder<T> {
  KonvoiSlidePageRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (AppMotion.reduceMotion(context)) {
              return child;
            }
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeOutCubic,
            );
            final slide = Tween<Offset>(
              begin: const Offset(1.0, 0),
              end: Offset.zero,
            ).animate(curved);

            return SlideTransition(
              position: slide,
              child: RepaintBoundary(child: child),
            );
          },
        );
}
