import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:touring_app/core/performance/load_balancer.dart';
import 'package:touring_app/core/performance/memory_cache.dart';
import 'package:touring_app/main.dart';
import 'package:touring_app/state/touring_controller.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> setViewport(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Advances modal/route/scroll transitions cleanly without blocking on looping WebP/Lottie assets.
  Future<void> pumpTransition(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 250));
  }

  test('LruTtlCache evicts oldest entry and tracks hit rate accurately', () {
    final cache = LruTtlCache<String, int>(maxEntries: 2);
    cache.put('a', 1);
    cache.put('b', 2);
    expect(cache.get('a'), 1);
    cache.put('c', 3);
    expect(cache.get('b'), isNull);
    expect(cache.get('a'), 1);
    expect(cache.get('c'), 3);
    expect(cache.evictionCount, 1);
    expect(cache.hitCount, 3);
    expect(cache.missCount, 1);
  });

  test('ClientLoadBalancer fails over automatically and coalesces concurrent requests', () async {
    final lb = ClientLoadBalancer();
    lb.setNodeHealth('id-jkt-1', false);

    int executions = 0;
    final futures = await Future.wait(<Future<LoadBalancedResponse<String>>>[
      lb.execute(
        dedupeKey: 'same-page',
        task: (node) async {
          executions++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return 'ok-${node.id}';
        },
      ),
      lb.execute(
        dedupeKey: 'same-page',
        task: (node) async {
          executions++;
          return 'ok-${node.id}';
        },
      ),
    ]);

    expect(executions, 1);
    expect(lb.coalescedCount, 1);
    expect(futures.first.nodeId, isNot('id-jkt-1'));
    expect(futures.first.data, futures.last.data);
  });

  testWidgets('Home flow: WebP hero, pagination, search empty state & join code', (tester) async {
    await setViewport(tester, const Size(390, 844));
    final controller = TouringController(simulatedNetworkDelay: Duration.zero);
    addTearDown(controller.dispose);

    await tester.pumpWidget(KonvoiApp(controller: controller));
    await pumpTransition(tester);

    expect(find.text('Jelajah'), findsOneWidget);
    expect(find.text('Halo Mip, gas konvoi!'), findsOneWidget);
    expect(controller.filteredRoutes.length, 4);

    // Open dedicated AllRoutesScreen via "Lihat Semua" (loads all 8 routes), verify & return
    await tester.tap(find.text('Lihat Semua'));
    await pumpTransition(tester);
    expect(controller.filteredRoutes.length, 8);
    expect(find.text('Semua Rute (8)'), findsOneWidget);
    await tester.pageBack();
    await pumpTransition(tester);

    // Open collapsible Search via "Cari" circle icon -> verify informative empty state (R-27) & reset
    await tester.tap(find.text('Cari'));
    await pumpTransition(tester);
    await tester.enterText(find.byType(TextField), 'RuteTidakAdaXYZ');
    await pumpTransition(tester);
    expect(find.text('Rute belum ditemukan'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await pumpTransition(tester);
    await tester.tap(find.text('Tampilkan Semua Rute'));
    await pumpTransition(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 260));
    await pumpTransition(tester);
    expect(find.text('Jalur Puncak Tomohon'), findsWidgets);

    // Open Join Code modal from Quick Action tile -> check validation then join valid code
    await tester.tap(find.text('Gabung'));
    await pumpTransition(tester);
    await tester.tap(find.text('Gabung ke Radar Konvoi'));
    await pumpTransition(tester);
    expect(find.text('Masukkan kode rute terlebih dahulu.'), findsOneWidget);

    await tester.tap(find.text('LKP-819 (Pantai)'));
    await pumpTransition(tester);
    await tester.tap(find.text('Gabung ke Radar Konvoi'));
    await pumpTransition(tester);

    expect(controller.currentTab, 1);
    expect(find.text('Pesisir Pantai Likupang'), findsOneWidget);
  });

  testWidgets('Live Radar flow: Gap Alert, Lottie Walkie-Talkie PTT, Hazard Pin, Crash SOS & Riding Mode', (tester) async {
    await setViewport(tester, const Size(390, 844));
    final controller = TouringController(simulatedNetworkDelay: Duration.zero);
    addTearDown(controller.dispose);
    controller.selectTab(1);

    await tester.pumpWidget(KonvoiApp(controller: controller));
    await pumpTransition(tester);

    // Toggle High-Contrast Riding Mode
    await tester.tap(find.byTooltip('High-Contrast Riding Mode'));
    await pumpTransition(tester);
    expect(controller.isRidingMode, isTrue);

    // Trigger Gap Alert (>500m)
    await tester.tap(find.text('Uji Gap Alert'));
    await pumpTransition(tester);
    expect(find.text('Gap Alert: Formasi Terpisah'), findsOneWidget);

    // Open Quick Hazard Pin Sheet and drop a pin
    await tester.tap(find.text('Bahaya'));
    await pumpTransition(tester);
    expect(find.text('Tandai Bahaya Jalan (1 Sentuhan)'), findsOneWidget);
    final beforePins = controller.hazardPins.length;
    await tester.tap(find.text('Jalan Berlubang'));
    await pumpTransition(tester);
    expect(controller.hazardPins.length, beforePins + 1);

    // Trigger Crash Detection 10s Countdown Overlay & cancel safely
    await tester.tap(find.text('SOS'));
    await pumpTransition(tester);
    expect(find.text('Apakah kamu baik-baik saja?'), findsOneWidget);
    await tester.tap(find.text('Saya Baik-Baik Saja (Batalkan)'));
    await pumpTransition(tester);
    expect(controller.isCrashAlertOpen, isFalse);

    // Hold Push-to-Talk -> Panda PTT + Lottie visualizer appears, release -> disappears
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Tahan Bicara (HT)')),
    );
    await pumpTransition(tester);
    expect(controller.isTalkingPtt, isTrue);
    expect(find.text('Siaran Suara Grup Aktif'), findsOneWidget);
    await gesture.up();
    await pumpTransition(tester);
    expect(controller.isTalkingPtt, isFalse);
  });

  testWidgets('Trips & Split-Bill flow: pagination, add expense & checkpoints', (tester) async {
    await setViewport(tester, const Size(390, 844));
    final controller = TouringController(simulatedNetworkDelay: Duration.zero);
    addTearDown(controller.dispose);
    controller.selectTab(2);

    await tester.pumpWidget(KonvoiApp(controller: controller));
    await pumpTransition(tester);

    expect(find.text('Perjalanan Saya'), findsOneWidget);
    expect(controller.filteredTrips.length, 3);

    // Paginate trips to load remaining 3 trips
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -320));
    await pumpTransition(tester);
    await tester.tap(find.text('Muat Perjalanan Lainnya'));
    await pumpTransition(tester);
    expect(controller.filteredTrips.length, 6);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 320));
    await pumpTransition(tester);
    await tester.tap(find.text('Sunday Ride Tomohon'));
    await pumpTransition(tester);

    expect(find.text('Total Pengeluaran Grup'), findsOneWidget);
    final initialExpenses = controller.allTrips.first.expenses.length;

    await tester.tap(find.text('Catat Pengeluaran Baru'));
    await pumpTransition(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Contoh: Isi bensin SPBU Winangun'),
      'Makan Siang Tinutuan',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Contoh: 160000'),
      '200000',
    );
    await tester.tap(find.text('Simpan & Bagi Rata (4 Rider)'));
    await pumpTransition(tester);

    expect(controller.allTrips.first.expenses.length, initialExpenses + 1);
    expect(find.text('Makan Siang Tinutuan'), findsOneWidget);
  });

  testWidgets('Profile WebP patches, Leaderboard pagination, Load Balancer sheet & 360px/1024px layout', (tester) async {
    final controller = TouringController(simulatedNetworkDelay: Duration.zero);
    addTearDown(controller.dispose);
    controller.selectTab(3);

    await setViewport(tester, const Size(360, 740));
    await tester.pumpWidget(KonvoiApp(controller: controller));
    await pumpTransition(tester);

    // Open Performa & Load Balancer sheet and verify node failover toggle
    await tester.tap(find.byTooltip('Performa & Load Balancer'));
    await pumpTransition(tester);
    expect(find.text('Performa & Load Balancer'), findsOneWidget);
    await tester.tap(find.text('id-jkt-1 (Jakarta Primary)'));
    await pumpTransition(tester);
    expect(controller.loadBalancer.lastServedNodeId, isNot('id-jkt-1'));
    await tester.ensureVisible(find.text('Selesai'));
    await pumpTransition(tester);
    await tester.tap(find.text('Selesai'));
    await pumpTransition(tester);

    // Open unlocked Digital Patch -> Lottie confetti + Panda celebration
    await tester.ensureVisible(find.text('Penakluk Tanjakan'));
    await pumpTransition(tester);
    await tester.tap(find.text('Penakluk Tanjakan'));
    await pumpTransition(tester);
    expect(find.text('Lencana Terbuka'), findsOneWidget);
    await tester.tap(find.text('Tutup'));
    await pumpTransition(tester);

    // Load more leaderboard entries (6 -> 10)
    await controller.loadMoreLeaderboard();
    await pumpTransition(tester);
    expect(controller.leaderboard.length, 10);

    // Wide 1024px tablet/desktop breakpoint -> NavigationRail reflow
    await setViewport(tester, const Size(1024, 768));
    await pumpTransition(tester);
    expect(find.byType(NavigationRail), findsOneWidget);
  });

  testWidgets('Circular FloatingNavBar sliding indicator & universal directional tab slides', (tester) async {
    await setViewport(tester, const Size(390, 844));
    final controller = TouringController(simulatedNetworkDelay: Duration.zero);
    addTearDown(controller.dispose);

    await tester.pumpWidget(KonvoiApp(controller: controller));
    await pumpTransition(tester);

    // Slide Home Category Tab (Semua -> Pantai)
    await tester.ensureVisible(find.text('Pantai'));
    await pumpTransition(tester);
    await tester.tap(find.text('Pantai'));
    await pumpTransition(tester);
    expect(find.text('Pesisir Pantai Likupang'), findsWidgets);

    // Tap across all 4 FloatingNavBar circular icon slots via Tooltip/Semantics
    await tester.tap(find.byTooltip('Radar'));
    await pumpTransition(tester);
    expect(controller.currentTab, 1);

    await tester.tap(find.byTooltip('Perjalanan'));
    await pumpTransition(tester);
    expect(controller.currentTab, 2);

    // Open Trip Detail and slide through Split-Bill -> Checkpoint -> Peserta
    await tester.tap(find.text('Sunday Ride Tomohon'));
    await pumpTransition(tester);
    await tester.tap(find.text('Checkpoint'));
    await pumpTransition(tester);
    expect(find.textContaining('Ketuk checkpoint'), findsOneWidget);

    await tester.tap(find.text('Peserta (4)'));
    await pumpTransition(tester);
    expect(find.text('Dimas Saputra'), findsOneWidget);
  });
}
