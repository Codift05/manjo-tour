import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app_shell.dart';
import 'core/theme/app_theme.dart';
import 'state/touring_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Cap decoded image memory cache to 40 MB / 80 entries so mobile stays smooth.
  PaintingBinding.instance.imageCache
    ..maximumSize = 80
    ..maximumSizeBytes = 40 << 20;
  runApp(const KonvoiApp());
}

class KonvoiApp extends StatefulWidget {
  const KonvoiApp({super.key, this.controller});

  final TouringController? controller;

  @override
  State<KonvoiApp> createState() => _KonvoiAppState();
}

class _KonvoiAppState extends State<KonvoiApp> {
  late final TouringController _controller;
  late final bool _ownsController;

  // Cache ThemeData once so GoogleFonts + TextTheme are NEVER rebuilt on tab/filter taps.
  late final ThemeData _lightTheme;
  late final ThemeData _ridingTheme;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TouringController();
    _lightTheme = AppTheme.light();
    _ridingTheme = AppTheme.riding();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TouringScope(
      controller: _controller,
      child: ValueListenableBuilder<bool>(
        valueListenable: _controller.ridingModeNotifier,
        builder: (context, riding, _) {
          SystemChrome.setSystemUIOverlayStyle(
            riding ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          );

          return MaterialApp(
            title: 'Konvoi',
            debugShowCheckedModeBanner: false,
            scrollBehavior: const _NoBounceScrollBehavior(),
            theme: _lightTheme,
            darkTheme: _ridingTheme,
            themeMode: riding ? ThemeMode.dark : ThemeMode.light,
            home: const AppShell(),
          );
        },
      ),
    );
  }
}

/// Clean clamping scroll behavior with zero rubber-band bounce and zero overscroll stretch.
class _NoBounceScrollBehavior extends MaterialScrollBehavior {
  const _NoBounceScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
