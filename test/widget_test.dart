import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_hackaton/config/arduino_config.dart';
import 'package:ui_hackaton/config/map_config.dart';
import 'package:ui_hackaton/main.dart';
import 'package:ui_hackaton/services/arduino_sensor_service.dart';
import 'package:ui_hackaton/services/blockchain_service.dart';
import 'package:ui_hackaton/services/mock_data_service.dart';
import 'package:ui_hackaton/screens/home_dashboard_screen.dart';
import 'package:ui_hackaton/screens/citizen_report_screen.dart';
import 'package:ui_hackaton/widgets/humidity_capsule_gauge.dart';
import 'package:ui_hackaton/widgets/interactive_map_canvas.dart';
import 'package:ui_hackaton/widgets/soil_radial_gauge.dart';

void main() {
  group('T.H.A.L.I.A UI & Functional Tests', () {
    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    test('Blockchain SHA-256 cryptographic service test', () {
      final hash = BlockchainService.calculateSha256('TEST_STRING');
      expect(hash.startsWith('0x'), isTrue);
      expect(hash.length, 66); // '0x' + 64 hex characters

      final reportHash = BlockchainService.generateReportHash(
        category: 'Air Berbau / Keruh',
        description: 'Pemeriksaan rutin',
        latitude: -6.229746,
        longitude: 106.855632,
        timestamp: DateTime(2026, 9, 18, 10, 0),
      );
      expect(reportHash.startsWith('0x'), isTrue);
      expect(reportHash.length, 66);

      final telemetryHash = BlockchainService.generateTelemetryHash(
        temperature: 28.0,
        ph: 7.2,
        soilMoisture: 38,
        timestamp: DateTime(2026, 9, 18, 7, 15),
      );
      expect(telemetryHash.startsWith('0x'), isTrue);
      expect(telemetryHash.length, 66);
    });

    testWidgets(
        'Layar 1 & 2: Home Dashboard and environmental cards render properly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        ArduinoSensorService.resetToDefault();
      });

      ArduinoSensorService.resetToDefault();

      await tester.pumpWidget(const ThaliaApp());
      await settle(tester);

      // Top Navigation Bar
      expect(find.text('Bantaran Ciliwung, Jkt'), findsOneWidget);
      expect(find.text('Solar 94% • Real-Time'), findsOneWidget);

      // Hero Weather Display (Nordic Ultra-Clean) with dummy temperature & dynamic date/greeting
      final now = DateTime.now();
      expect(find.text('28°'), findsOneWidget);
      expect(find.text('Terasa seperti 30°'), findsOneWidget);
      expect(find.text(HomeDashboardScreen.formatGreeting(now)), findsOneWidget);
      expect(
        find.text(HomeDashboardScreen.formatIndonesianDate(now)),
        findsOneWidget,
      );
      expect(find.text('🍃  Kondisi Aman • Udara Bersih'), findsOneWidget);

      // Environmental Glance (Only 2 pillars: Kelembapan & Tanah; Hidrosfer removed)
      expect(find.text('Kelembapan'), findsOneWidget);
      expect(find.text('Tanah'), findsOneWidget);
      expect(find.text('Kualitas Air'), findsNothing);

      // Condition Cards (Hidrosfer card removed)
      expect(find.text('Hidrosfer (Kualitas Air)'), findsNothing);
      expect(find.text('Atmosfer (Sirkulasi Udara)'), findsOneWidget);
      expect(find.text('Litosfer (Kelembapan Tanah)'), findsOneWidget);
      expect(
        find.text('Data Terkunci di Smart Contract Sepolia • Hash SHA-256 Valid'),
        findsOneWidget,
      );

      // Verify equal height between Atmosfer (Kelembapan) and Litosfer (Tanah) bento cards
      final RenderBox atmosferBox = tester.renderObject(
        find.byKey(const ValueKey('bento-atmosfer-card')),
      );
      final RenderBox litosferBox = tester.renderObject(
        find.byKey(const ValueKey('bento-litosfer-card')),
      );
      expect(atmosferBox.size.height, equals(litosferBox.size.height));
      expect(atmosferBox.size.height, greaterThan(150.0));

      // Verify no banned water level cm or debit numbers
      expect(find.textContaining('cm debit'), findsNothing);
      expect(find.textContaining('ketinggian air cm'), findsNothing);
    });

    testWidgets(
        'Layar 2 Detail Sheet: Tapping condition cards opens respective modals',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ThaliaApp());
      await settle(tester);

      // 1. Verify Hidrosfer card does not exist
      expect(find.text('Hidrosfer (Kualitas Air)'), findsNothing);

      // 2. Tap Atmosfer card
      await tester.tap(find.text('Atmosfer (Sirkulasi Udara)'));
      await settle(tester);
      expect(find.text('Metrik Udara Mikro'), findsOneWidget);
      expect(find.text('Indeks AQI'), findsOneWidget);
      await tester.tap(find.text('Tutup Rincian'));
      await settle(tester);

      // 3. Tap Litosfer card
      await tester.tap(find.text('Litosfer (Kelembapan Tanah)'));
      await settle(tester);
      expect(find.text('Indikator Geoteknik'), findsOneWidget);
      expect(find.text('Kemiringan Lereng'), findsOneWidget);
      await tester.tap(find.text('Tutup Rincian'));
      await settle(tester);
    });

    testWidgets(
        'Layar 2 Sepolia On-Chain: Tapping proof card opens proof detail modal',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ThaliaApp());
      await settle(tester);

      // Tap on-chain card
      await tester.tap(
        find.text('Data Terkunci di Smart Contract Sepolia • Hash SHA-256 Valid'),
      );
      await settle(tester);

      expect(find.text('Bukti Integritas On-Chain'), findsOneWidget);
      expect(find.text('Ethereum Sepolia Testnet'), findsOneWidget);
      expect(find.text('Salin Bukti Transaksi SHA-256'), findsOneWidget);

      await tester.tap(find.text('Salin Bukti Transaksi SHA-256'));
      await settle(tester);
    });

    testWidgets(
        'Layar 3: Radar Peta screen navigation, search filter, and empty query',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ThaliaApp());
      await settle(tester);

      // Navigate to Radar Peta via Dot 1
      await tester.tap(find.byKey(const ValueKey('page-indicator-dot-1')));
      await settle(tester);

      expect(find.text('Cari wilayah / pos pantau...'), findsOneWidget);
      expect(find.text('Kondisi Wilayah Sekitar'), findsOneWidget);

      // Search non-existent station
      await tester.enterText(
        find.byType(TextField),
        'WilayahTidakAda999',
      );
      await settle(tester);
      expect(
        find.text('Tidak ada pos pantau yang cocok dengan pencarian.'),
        findsOneWidget,
      );

      // Clear search
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await settle(tester);

      expect(find.textContaining('Jakarta Timur (1.8 km)'), findsOneWidget);
      expect(find.textContaining('Jakarta Selatan (3.4 km)'), findsOneWidget);

      // Verify no pH or water quality in radar map station cards
      expect(find.textContaining('pH '), findsNothing);
      expect(find.textContaining('Kualitas Air'), findsNothing);
      expect(find.textContaining('Solar 96% Aktif'), findsOneWidget);
    });

    testWidgets(
        'Layar 4: Lapor Warga validation and submission flow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ThaliaApp());
      await settle(tester);

      // Navigate to Lapor Warga via Dot 2
      await tester.tap(find.byKey(const ValueKey('page-indicator-dot-2')));
      await settle(tester);

      // 1. Edge Case: Empty submission
      await tester.tap(find.text('Kirim Laporan & Kunci ke Blockchain'));
      await settle(tester);
      expect(
        find.text('Harap masukkan deskripsi singkat keadaan.'),
        findsOneWidget,
      );

      // 2. Select category & submit valid report
      await tester.tap(find.text('Retakan Lereng').first);
      await settle(tester);

      await tester.enterText(
        find.byType(TextField),
        'Terdeteksi retakan tanah kecil pasca hujan.',
      );
      await settle(tester);

      await tester.tap(find.text('Kirim Laporan & Kunci ke Blockchain'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await settle(tester);

      expect(find.text('Laporan Berhasil Dicatat!'), findsOneWidget);
      expect(find.text('SHA-256 Proof Hash'), findsOneWidget);

      await tester.tap(find.text('Kembali ke Laporan'));
      await settle(tester);

      expect(find.text('Terdeteksi retakan tanah kecil pasca hujan.'),
          findsOneWidget);
    });

    testWidgets(
        'Navigation & Gesture: Horizontal PageView swipe and 3-dot indicator switch pages',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ThaliaApp());
      await settle(tester);

      // Check 3 dots exist
      expect(find.byKey(const ValueKey('page-indicator-dot-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('page-indicator-dot-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('page-indicator-dot-2')), findsOneWidget);

      // Verify Page 0 (Beranda) is active
      expect(find.text('28°'), findsOneWidget);

      // Gesture 1: swipe left from Page 0 to Page 1 (Radar Peta)
      await tester.fling(find.byType(PageView), const Offset(-600, 0), 1000);
      await settle(tester);
      expect(find.text('Cari wilayah / pos pantau...'), findsOneWidget);

      // Gesture 2: swipe left from Page 1 to Page 2 (Lapor Warga)
      await tester.fling(find.byType(PageView), const Offset(-600, 0), 1000);
      await settle(tester);
      expect(find.text('Lapor Warga'), findsOneWidget);

      // Gesture 3: swipe right from Page 2 back to Page 1 (Radar Peta)
      await tester.fling(find.byType(PageView), const Offset(600, 0), 1000);
      await settle(tester);
      expect(find.text('Cari wilayah / pos pantau...'), findsOneWidget);

      // Gesture 4: swipe right from Page 1 back to Page 0 (Beranda)
      await tester.fling(find.byType(PageView), const Offset(600, 0), 1000);
      await settle(tester);
      expect(find.text('28°'), findsOneWidget);

      // Dot Navigation: Tap Dot 2 -> Lapor Warga
      await tester.tap(find.byKey(const ValueKey('page-indicator-dot-2')));
      await settle(tester);
      expect(find.text('Lapor Warga'), findsOneWidget);

      // Dot Navigation: Tap Dot 1 -> Radar Peta
      await tester.tap(find.byKey(const ValueKey('page-indicator-dot-1')));
      await settle(tester);
      expect(find.text('Cari wilayah / pos pantau...'), findsOneWidget);

      // Dot Navigation: Tap Dot 0 -> Beranda
      await tester.tap(find.byKey(const ValueKey('page-indicator-dot-0')));
      await settle(tester);
      expect(find.text('28°'), findsOneWidget);

      // Verify Riwayat screen is completely removed from navigation
      expect(find.text('Riwayat & Kalender Faktual'), findsNothing);
      expect(find.text('Riwayat'), findsNothing);
    });

    testWidgets('Drawer info modal renders properly from hamburger menu',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ThaliaApp());
      await settle(tester);

      // Open drawer via menu button
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await settle(tester);

      expect(find.text('HackSphere 2026 • Tim Ayam Kecap Paijo'), findsOneWidget);
      expect(find.textContaining('Politeknik Astra'), findsOneWidget);
      expect(find.text('Riwayat & Kalender Faktual'), findsNothing);
    });

    testWidgets(
        'Layar 3: Map renders citizen report pins and bottom sheet tabs switch cleanly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ThaliaApp());
      await settle(tester);

      // Navigate to Radar Peta via Dot 1
      await tester.tap(find.byKey(const ValueKey('page-indicator-dot-1')));
      await settle(tester);

      // Check both tabs exist
      expect(find.textContaining('Pos Pantau (5)'), findsOneWidget);
      expect(find.textContaining('Laporan Warga'), findsOneWidget);

      // Switch to Laporan Warga tab
      await tester.tap(find.textContaining('Laporan Warga'));
      await settle(tester);

      expect(find.text('Air Berbau / Keruh'), findsAtLeastNWidgets(1));
      expect(find.text('Kunci On-Chain Valid'), findsAtLeastNWidgets(1));

      // Tap on a report card in bottom sheet to open detail modal
      await tester.tap(find.text('Air Berbau / Keruh').first);
      await settle(tester);

      expect(find.text('Kunci Bukti Blockchain (SHA-256 Valid)'), findsOneWidget);
      expect(find.text('Tutup Detail'), findsOneWidget);

      await tester.tap(find.text('Tutup Detail'));
      await settle(tester);
    });

    testWidgets(
        'Layar 4: Tapping report in public feed opens verified blockchain proof sheet',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ThaliaApp());
      await settle(tester);

      // Navigate to Lapor Warga via Dot 2
      await tester.tap(find.byKey(const ValueKey('page-indicator-dot-2')));
      await settle(tester);

      // Scroll and tap first public report item in feed
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('report-card-rep-001')),
        200.0,
        scrollable: find.descendant(
          of: find.byType(CitizenReportScreen),
          matching: find.byType(Scrollable),
        ).first,
      );
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('report-card-rep-001')));
      await settle(tester);

      expect(find.text('Kunci Bukti Blockchain (SHA-256 Valid)'), findsOneWidget);
      expect(find.text('Salin Hash'), findsOneWidget);

      await tester.tap(find.text('Salin Hash'));
      await settle(tester);

      expect(find.text('Hash SHA-256 berhasil disalin!'), findsOneWidget);

      await tester.tap(find.text('Tutup'));
      await settle(tester);
    });

    testWidgets(
        'Cross-screen synchronization: Submitting report in Layar 4 updates Layar 3 Radar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      MockDataService.resetCitizenReports();

      await tester.pumpWidget(const ThaliaApp());
      await settle(tester);

      // Go to Layar 4 via Dot 2 and submit
      await tester.tap(find.byKey(const ValueKey('page-indicator-dot-2')));
      await settle(tester);

      await tester.enterText(
        find.byType(TextField),
        'Pohon trembesi miring ke arah sungai Ciliwung.',
      );
      await settle(tester);

      await tester.tap(find.text('Kirim Laporan & Kunci ke Blockchain'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await settle(tester);

      await tester.tap(find.text('Kembali ke Laporan'));
      await settle(tester);

      // Navigate to Layar 3 Radar Peta via Dot 1
      await tester.tap(find.byKey(const ValueKey('page-indicator-dot-1')));
      await settle(tester);

      // Switch to Laporan Warga
      await tester.tap(find.textContaining('Laporan Warga'));
      await settle(tester);

      expect(
        find.text('Pohon trembesi miring ke arah sungai Ciliwung.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'Robustness: Small mobile screen (360x640) renders without overflow errors',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ThaliaApp());
      await settle(tester);

      // Verify Layar 1 elements on small screen
      expect(find.text('28°'), findsOneWidget);
      expect(find.text('Bantaran Ciliwung, Jkt'), findsOneWidget);

      // Verify equal height on small 360x640 screen
      final RenderBox smallAtmosferBox = tester.renderObject(
        find.byKey(const ValueKey('bento-atmosfer-card')),
      );
      final RenderBox smallLitosferBox = tester.renderObject(
        find.byKey(const ValueKey('bento-litosfer-card')),
      );
      expect(smallAtmosferBox.size.height, equals(smallLitosferBox.size.height));

      // Scroll to Atmosfer and tap to open detail sheet
      await tester.scrollUntilVisible(
        find.text('Atmosfer (Sirkulasi Udara)'),
        200.0,
        scrollable: find.descendant(
          of: find.byType(HomeDashboardScreen),
          matching: find.byType(Scrollable),
        ).first,
      );
      await settle(tester);
      await tester.tap(find.text('Atmosfer (Sirkulasi Udara)'));
      await settle(tester);

      expect(find.text('Metrik Udara Mikro'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Tutup Rincian'), warnIfMissed: false);
      await settle(tester);
    });

    testWidgets(
        'Robustness: Small screen (360x640) with 1.5x font scale maintains equal bento height and no overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await tester.pumpWidget(const ThaliaApp());
      await settle(tester);

      final RenderBox atmosferBox = tester.renderObject(
        find.byKey(const ValueKey('bento-atmosfer-card')),
      );
      final RenderBox litosferBox = tester.renderObject(
        find.byKey(const ValueKey('bento-litosfer-card')),
      );
      expect(atmosferBox.size.height, equals(litosferBox.size.height));
      expect(tester.takeException(), isNull);

      // Navigate to Radar Peta on small screen + 1.5x font scale and verify no overflow
      await tester.tap(find.byKey(const ValueKey('page-indicator-dot-1')));
      await settle(tester);
      expect(find.text('Google Maps'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('MapConfig & Web Mercator coordinates verification for DKI Jakarta', () {
      expect(MapConfig.googleMapsApiKey, isNotEmpty);
      expect(MapConfig.userGpsLat, closeTo(-6.2250, 0.0001));
      expect(MapConfig.userGpsLng, closeTo(106.8600, 0.0001));

      final stations = MockDataService.surroundingStations;
      final jaktim = stations.firstWhere((s) => s.id == 'node-jaktim');
      final jaksel = stations.firstWhere((s) => s.id == 'node-jaksel');
      final jakpus = stations.firstWhere((s) => s.id == 'node-jakpus');
      final jakbar = stations.firstWhere((s) => s.id == 'node-jakbar');
      final jakut = stations.firstWhere((s) => s.id == 'node-jakut');

      expect(jaktim.latitude, closeTo(-6.2320, 0.0001));
      expect(jaktim.longitude, closeTo(106.8670, 0.0001));
      expect(jaksel.latitude, closeTo(-6.2150, 0.0001));
      expect(jaksel.longitude, closeTo(106.8480, 0.0001));
      expect(jakpus.latitude, closeTo(-6.1950, 0.0001));
      expect(jakpus.longitude, closeTo(106.8320, 0.0001));
      expect(jakbar.latitude, closeTo(-6.1780, 0.0001));
      expect(jakbar.longitude, closeTo(106.7950, 0.0001));
      expect(jakut.latitude, closeTo(-6.1280, 0.0001));
      expect(jakut.longitude, closeTo(106.8350, 0.0001));

      final googleUrl = MapConfig.resolveTileUrl(
        style: MapTileStyle.googleStandard,
        z: 12,
        x: 3263,
        y: 2120,
      );
      expect(googleUrl, contains('https://mt1.google.com/vt/lyrs=m'));
      expect(googleUrl, contains('x=3263&y=2120&z=12'));

      final nordicUrl = MapConfig.resolveTileUrl(
        style: MapTileStyle.nordicLight,
        z: 12,
        x: 3263,
        y: 2120,
      );
      expect(
        nordicUrl,
        equals('https://basemaps.cartocdn.com/light_all/12/3263/2120.png'),
      );

      final px = InteractiveMapCanvas.latLngToWorldPixel(
        MapConfig.userGpsLat,
        MapConfig.userGpsLng,
        12.0,
      );
      final roundTrip = InteractiveMapCanvas.worldPixelToLatLng(
        px.dx,
        px.dy,
        12.0,
      );
      expect(roundTrip.$1, closeTo(MapConfig.userGpsLat, 0.0001));
      expect(roundTrip.$2, closeTo(MapConfig.userGpsLng, 0.0001));
    });

    testWidgets(
        'Layar 3: Real Jakarta tile map layer switch, zoom controls, and pin focus work smoothly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ThaliaApp());
      await settle(tester);

      // Navigate to Radar Peta via Dot 1
      await tester.tap(find.byKey(const ValueKey('page-indicator-dot-1')));
      await settle(tester);

      // Default layer is Google Maps
      expect(find.text('Google Maps'), findsOneWidget);
      expect(find.text('Google Maps Asli • DKI Jakarta'), findsOneWidget);
      expect(find.text('GPS Anda (Ciliwung)'), findsOneWidget);

      // Switch layer to Nordic Light (CartoDB)
      await tester.tap(find.byKey(const ValueKey('map-layer-switch-button')));
      await settle(tester);
      expect(find.text('Nordic Light'), findsOneWidget);
      expect(find.text('Nordic Light (CartoDB) • DKI Jakarta'), findsOneWidget);

      // Switch layer to Satelit
      await tester.tap(find.byKey(const ValueKey('map-layer-switch-button')));
      await settle(tester);
      expect(find.text('Satelit'), findsOneWidget);
      expect(find.text('Google Satelit • DKI Jakarta'), findsOneWidget);

      // Switch back to Google Maps
      await tester.tap(find.byKey(const ValueKey('map-layer-switch-button')));
      await settle(tester);
      expect(find.text('Google Maps'), findsOneWidget);

      // At initial zoom (12.0), tap station pins and user GPS pin directly to verify zero pin overlap
      await tester.tap(find.byKey(const ValueKey('map-station-pin-node-jaksel')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('map-reset-overview-badge')));
      await settle(tester);

      await tester.tap(find.byKey(const ValueKey('user-gps-pin')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('map-reset-overview-badge')));
      await settle(tester);

      await tester.tap(find.byKey(const ValueKey('map-station-pin-node-jaktim')));
      await settle(tester);

      // Zoom in, zoom out, and recenter GPS
      await tester.tap(find.byKey(const ValueKey('map-zoom-in-button')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('map-zoom-out-button')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('map-gps-center-button')));
      await settle(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Layar 3: Search filter updates both station pins and citizen report pins on map, and collapsed sheet expands map gesture area',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      MockDataService.resetCitizenReports();

      await tester.pumpWidget(const ThaliaApp());
      await settle(tester);

      // Navigate to Radar Peta via Dot 1
      await tester.tap(find.byKey(const ValueKey('page-indicator-dot-1')));
      await settle(tester);

      // Initially all 3 report pins exist on map
      expect(find.byKey(const ValueKey('map-report-pin-rep-001')), findsOneWidget);
      expect(find.byKey(const ValueKey('map-report-pin-rep-002')), findsOneWidget);
      expect(find.byKey(const ValueKey('map-report-pin-rep-003')), findsOneWidget);

      // Search for 'Retakan' -> only rep-003 matches; station pins & other report pins filtered out
      await tester.enterText(find.byType(TextField), 'Retakan');
      await settle(tester);

      expect(find.byKey(const ValueKey('map-report-pin-rep-003')), findsOneWidget);
      expect(find.byKey(const ValueKey('map-report-pin-rep-001')), findsNothing);
      expect(find.byKey(const ValueKey('map-report-pin-rep-002')), findsNothing);
      expect(find.byKey(const ValueKey('map-station-pin-node-jaktim')), findsNothing);

      // Clear search -> all pins return
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await settle(tester);
      expect(find.byKey(const ValueKey('map-report-pin-rep-001')), findsOneWidget);
      expect(find.byKey(const ValueKey('map-station-pin-node-jaktim')), findsOneWidget);

      // Collapse DraggableScrollableSheet toward 0.18 peek size
      await tester.drag(find.text('Kondisi Wilayah Sekitar'), const Offset(0, 750));
      await settle(tester);

      // Perform a two-finger pinch-zoom gesture in the lower map area (y = 1500, i.e. 0.625 * height)
      final center = const Offset(540, 1500);
      final pointer1 = await tester.startGesture(center - const Offset(60, 0));
      final pointer2 = await tester.startGesture(center + const Offset(60, 0));
      await tester.pump();
      await pointer1.moveTo(center - const Offset(140, 0));
      await pointer2.moveTo(center + const Offset(140, 0));
      await tester.pump(const Duration(milliseconds: 50));
      // Pinch back near 1.01x to verify no scale deadzone
      await pointer1.moveTo(center - const Offset(61, 0));
      await pointer2.moveTo(center + const Offset(61, 0));
      await tester.pump(const Duration(milliseconds: 50));
      await pointer1.up();
      await pointer2.up();
      await settle(tester);

      expect(tester.takeException(), isNull);
    });

    test('Dynamic Indonesian greeting and date formatting covers all periods and calendar names', () {
      // Greeting periods
      expect(HomeDashboardScreen.formatGreeting(DateTime(2026, 10, 13, 4, 0)), 'selamat pagi,');
      expect(HomeDashboardScreen.formatGreeting(DateTime(2026, 10, 13, 10, 59)), 'selamat pagi,');
      expect(HomeDashboardScreen.formatGreeting(DateTime(2026, 10, 13, 11, 0)), 'selamat siang,');
      expect(HomeDashboardScreen.formatGreeting(DateTime(2026, 10, 13, 14, 59)), 'selamat siang,');
      expect(HomeDashboardScreen.formatGreeting(DateTime(2026, 10, 13, 15, 0)), 'selamat sore,');
      expect(HomeDashboardScreen.formatGreeting(DateTime(2026, 10, 13, 17, 59)), 'selamat sore,');
      expect(HomeDashboardScreen.formatGreeting(DateTime(2026, 10, 13, 18, 0)), 'selamat malam,');
      expect(HomeDashboardScreen.formatGreeting(DateTime(2026, 10, 13, 2, 30)), 'selamat malam,');

      // Days and months formatting
      expect(
        HomeDashboardScreen.formatIndonesianDate(DateTime(2026, 10, 13)),
        'SELASA 13 OKTOBER 2026',
      );
      expect(
        HomeDashboardScreen.formatIndonesianDate(DateTime(2026, 9, 18)),
        'JUMAT 18 SEPTEMBER 2026',
      );
      expect(
        HomeDashboardScreen.formatIndonesianDate(DateTime(2026, 1, 5)),
        'SENIN 5 JANUARI 2026',
      );
      expect(
        HomeDashboardScreen.formatIndonesianDate(DateTime(2026, 12, 27)),
        'MINGGU 27 DESEMBER 2026',
      );
    });

    testWidgets(
        'ArduinoSensorService: Reactive soil moisture & humidity updates reflect in HomeDashboardScreen, gauges, and open detail sheet while keeping temperature dummy',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        ArduinoSensorService.resetToDefault();
      });

      ArduinoSensorService.resetToDefault();
      expect(ArduinoConfig.keepTemperatureDummy, isTrue);
      expect(ArduinoConfig.pythonServerEndpoint, contains('/api/sensor'));

      await tester.pumpWidget(
        MaterialApp(
          home: HomeDashboardScreen(
            currentDateTime: DateTime(2026, 10, 13, 13, 30),
          ),
        ),
      );
      await settle(tester);

      // Verify custom date & greeting rendered
      expect(find.text('selamat siang,'), findsOneWidget);
      expect(find.text('SELASA 13 OKTOBER 2026'), findsOneWidget);

      // Default values: 38% soil moisture, 72% air humidity, 28° dummy temp
      expect(find.text('38%'), findsOneWidget);
      expect(find.text('72%'), findsAtLeastNWidgets(1));
      expect(find.text('28°'), findsOneWidget);
      expect(find.text('Terasa seperti 30°'), findsOneWidget);

      // 1. Update soil moisture from Arduino service -> UI & SoilRadialGauge update reactively
      ArduinoSensorService.updateSoilMoisture(64);
      await settle(tester);

      expect(find.text('64%'), findsOneWidget);
      expect(find.text('38%'), findsNothing);
      expect(find.text('28°'), findsOneWidget);
      final SoilRadialGauge cardGauge = tester.widget(find.byType(SoilRadialGauge));
      expect(cardGauge.soilPercent, 64);

      // Open Litosfer detail sheet and verify live reactivity WHILE the sheet is open
      await tester.tap(find.text('Litosfer (Kelembapan Tanah)'));
      await settle(tester);
      expect(find.text('64%'), findsAtLeastNWidgets(1));

      // Update soil moisture while ConditionsDetailSheet is still open!
      ArduinoSensorService.updateSoilMoisture(
        42,
        landslideRisk: 'Rendah',
        soilStructure: 'Lempung Pasir Padat',
      );
      await settle(tester);
      expect(find.text('42%'), findsAtLeastNWidgets(2)); // Both background card and open detail sheet
      expect(find.text('Risiko Longsor: Rendah'), findsOneWidget);
      expect(find.text('Lempung Pasir Padat'), findsOneWidget);

      await tester.tap(find.text('Tutup Rincian'));
      await settle(tester);

      // 2. Apply JSON payload from Python server (with boundary values & dummy temperature check)
      ArduinoSensorService.applyJsonPayload({
        'soil_moisture': 85,
        'humidity': '79%',
        'pressure': 1009,
        'temperature': 99.0, // Should be ignored because keepTemperatureDummy is true
        'feels_like': 99.0,
      });
      await settle(tester);

      expect(find.text('85%'), findsOneWidget);
      expect(find.text('Stabil • Risiko Waspada (Tanah Jenuh Air)'), findsOneWidget);
      // Both HumidityCapsuleGauge inner label AND card footer label must show 79% after animation settles
      expect(find.text('79%'), findsNWidgets(2));
      final HumidityCapsuleGauge humidityGauge =
          tester.widget(find.byType(HumidityCapsuleGauge));
      expect(humidityGauge.humidityPercent, 79);
      expect(find.text('Normal • 1009 hPa'), findsOneWidget);
      // Temperature must remain dummy 28° / 30°
      expect(find.text('28°'), findsOneWidget);
      expect(find.text('Terasa seperti 30°'), findsOneWidget);

      // 3. Partial JSON payload without soil_moisture preserves custom landslide_risk
      ArduinoSensorService.applyJsonPayload({
        'soil_moisture': 42,
        'landslide_risk': 'Rendah',
      });
      ArduinoSensorService.applyJsonPayload({
        'slope_angle': 14.5,
      });
      await settle(tester);
      expect(ArduinoSensorService.currentLitosfer.soilMoisture, 42);
      expect(ArduinoSensorService.currentLitosfer.landslideRisk, 'Rendah');
      expect(ArduinoSensorService.currentLitosfer.slopeAngle, 14.5);

      // 4. Test clamping boundaries (< 0 and > 100)
      ArduinoSensorService.updateSoilMoisture(-15);
      await settle(tester);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('Stabil • Risiko Rendah (Tanah Kering)'), findsOneWidget);

      ArduinoSensorService.updateSoilMoisture(140);
      await settle(tester);
      expect(find.text('100%'), findsOneWidget);

      // 5. Test graceful offline fallback when Python server is unreachable
      final ok = await ArduinoSensorService.fetchFromPythonServer(
        endpointUrl: 'http://127.0.0.1:59999/api/sensor',
        timeout: const Duration(milliseconds: 100),
      );
      expect(ok, isFalse);
      expect(ArduinoSensorService.isConnectedNotifier.value, isFalse);
      // Existing value remains intact without crash
      expect(ArduinoSensorService.soilMoisture, 100);
    });

    test(
        'ArduinoSensorService: Live HTTP GET from local Python server parses JSON and falls back cleanly on error',
        () async {
      ArduinoSensorService.resetToDefault();
      addTearDown(ArduinoSensorService.resetToDefault);

      await HttpOverrides.runWithHttpOverrides(() async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));

        server.listen((HttpRequest request) async {
          if (request.uri.path == '/api/sensor') {
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({
              'soil_moisture': 42,
              'humidity': 70,
              'pressure': 1012,
              'landslide_risk': 'Rendah',
              'temperature': 99.0,
            }));
          } else if (request.uri.path == '/api/plain') {
            request.response.statusCode = HttpStatus.ok;
            request.response.write('55');
          } else {
            request.response.statusCode = HttpStatus.internalServerError;
          }
          await request.response.close();
        });

        final baseUrl = 'http://127.0.0.1:${server.port}';

        // 1. Valid JSON response matching expected Python server schema
        final ok = await ArduinoSensorService.fetchFromPythonServer(
          endpointUrl: '$baseUrl/api/sensor',
        );
        expect(ok, isTrue);
        expect(ArduinoSensorService.isConnectedNotifier.value, isTrue);
        expect(ArduinoSensorService.soilMoisture, 42);
        expect(ArduinoSensorService.currentLitosfer.landslideRisk, 'Rendah');
        expect(ArduinoSensorService.currentAtmosfer.humidity, 70);
        expect(ArduinoSensorService.currentAtmosfer.pressure, 1012);
        // Dummy temperature must remain 28.0 / 30.0
        expect(ArduinoSensorService.currentAtmosfer.temperature, 28.0);
        expect(ArduinoSensorService.currentAtmosfer.feelsLike, 30.0);

        // 2. Plain numeric response fallback
        final okPlain = await ArduinoSensorService.fetchFromPythonServer(
          endpointUrl: '$baseUrl/api/plain',
        );
        expect(okPlain, isTrue);
        expect(ArduinoSensorService.soilMoisture, 55);

        // 3. HTTP 500 error fallback
        final okError = await ArduinoSensorService.fetchFromPythonServer(
          endpointUrl: '$baseUrl/api/error',
        );
        expect(okError, isFalse);
        expect(ArduinoSensorService.isConnectedNotifier.value, isFalse);
        // Retains last valid reading (55%) without crashing
        expect(ArduinoSensorService.soilMoisture, 55);
      }, _RealNetworkHttpOverrides());
    });
  });
}

class _RealNetworkHttpOverrides extends HttpOverrides {}


