import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/map_config.dart';
import '../theme/app_colors.dart';
import '../models/station_node.dart';
import '../models/citizen_report.dart';
import '../widgets/pulsing_dot.dart';

/// Peta Interaktif Real-Tile DKI Jakarta & Sungai Ciliwung (Web Mercator EPSG:3857)
/// Menampilkan jalanan asli, aliran Sungai Ciliwung, titik GPS pengguna berdenyut,
/// pos pantau wilayah sekitar, dan pin laporan warga dengan koordinat nyata.
/// Mendukung pergantian layer antara Google Maps Asli, Nordic Light (CartoDB), dan Satelit.
class InteractiveMapCanvas extends StatefulWidget {
  final List<StationNode> stations;
  final StationNode? selectedStation;
  final ValueChanged<StationNode> onSelectStation;
  final List<CitizenReport> citizenReports;
  final CitizenReport? selectedReport;
  final ValueChanged<CitizenReport>? onSelectReport;
  final int focusTrigger;
  final double bottomSheetExtent;

  const InteractiveMapCanvas({
    super.key,
    required this.stations,
    this.selectedStation,
    required this.onSelectStation,
    this.citizenReports = const [],
    this.selectedReport,
    this.onSelectReport,
    this.focusTrigger = 0,
    this.bottomSheetExtent = 0.50,
  });

  /// Proyeksi Web Mercator (EPSG:3857): Latitude/Longitude ke koordinat piksel dunia
  static Offset latLngToWorldPixel(double lat, double lng, double zoom) {
    final worldSize = 256.0 * math.pow(2.0, zoom);
    final x = (lng + 180.0) / 360.0 * worldSize;
    final clampedLat = lat.clamp(-85.05112878, 85.05112878);
    final latRad = clampedLat * math.pi / 180.0;
    final y = (1.0 -
            math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
        2.0 *
        worldSize;
    return Offset(x, y);
  }

  /// Kebalikan proyeksi Web Mercator: piksel dunia ke Latitude/Longitude
  static (double lat, double lng) worldPixelToLatLng(
    double wx,
    double wy,
    double zoom,
  ) {
    final worldSize = 256.0 * math.pow(2.0, zoom);
    final lng = (wx / worldSize) * 360.0 - 180.0;
    final n = math.pi - 2.0 * math.pi * (wy / worldSize);
    final lat =
        180.0 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
    return (lat.clamp(-85.0511, 85.0511), lng.clamp(-180.0, 180.0));
  }

  @override
  State<InteractiveMapCanvas> createState() => _InteractiveMapCanvasState();
}

class _InteractiveMapCanvasState extends State<InteractiveMapCanvas>
    with SingleTickerProviderStateMixin {
  MapTileStyle _layerStyle = MapTileStyle.googleStandard;

  double _centerLat = MapConfig.initialCenterLat;
  double _centerLng = MapConfig.initialCenterLng;
  double _zoom = MapConfig.initialZoom;

  late final AnimationController _cameraController;
  double _animStartLat = MapConfig.initialCenterLat;
  double _animStartLng = MapConfig.initialCenterLng;
  double _animStartZoom = MapConfig.initialZoom;
  double _animTargetLat = MapConfig.initialCenterLat;
  double _animTargetLng = MapConfig.initialCenterLng;
  double _animTargetZoom = MapConfig.initialZoom;

  Offset? _lastFocalPoint;
  double? _scaleStartZoom;

  @override
  void initState() {
    super.initState();
    _cameraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(_onCameraAnimationTick);
  }

  void _onCameraAnimationTick() {
    final t = Curves.easeOutCubic.transform(_cameraController.value);
    setState(() {
      _centerLat = _animStartLat + (_animTargetLat - _animStartLat) * t;
      _centerLng = _animStartLng + (_animTargetLng - _animStartLng) * t;
      _zoom = _animStartZoom + (_animTargetZoom - _animStartZoom) * t;
    });
  }

  void _animateCameraTo({
    required double lat,
    required double lng,
    double? targetZoom,
  }) {
    _animStartLat = _centerLat;
    _animStartLng = _centerLng;
    _animStartZoom = _zoom;
    _animTargetLat = lat.clamp(-6.45, -6.00);
    _animTargetLng = lng.clamp(106.60, 107.05);
    _animTargetZoom = (targetZoom ?? _zoom).clamp(10.5, 17.5);
    _cameraController.forward(from: 0.0);
  }

  @override
  void didUpdateWidget(covariant InteractiveMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    final stationChanged =
        widget.selectedStation?.id != oldWidget.selectedStation?.id;
    final reportChanged =
        widget.selectedReport?.id != oldWidget.selectedReport?.id;
    final triggerChanged = widget.focusTrigger != oldWidget.focusTrigger;

    if (widget.selectedStation != null && (stationChanged || triggerChanged)) {
      final st = widget.selectedStation!;
      _animateCameraTo(
        lat: st.latitude,
        lng: st.longitude,
        targetZoom: math.max(_zoom, 13.2),
      );
    } else if (widget.selectedReport != null &&
        (reportChanged || triggerChanged)) {
      final pos = _effectiveReportLatLng(widget.selectedReport!);
      _animateCameraTo(
        lat: pos.$1,
        lng: pos.$2,
        targetZoom: math.max(_zoom, 13.6),
      );
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _cycleMapLayer() {
    HapticFeedback.selectionClick();
    setState(() {
      switch (_layerStyle) {
        case MapTileStyle.googleStandard:
          _layerStyle = MapTileStyle.nordicLight;
          break;
        case MapTileStyle.nordicLight:
          _layerStyle = MapTileStyle.googleHybrid;
          break;
        case MapTileStyle.googleHybrid:
          _layerStyle = MapTileStyle.googleStandard;
          break;
      }
    });
  }

  void _zoomBy(double delta) {
    HapticFeedback.lightImpact();
    _animateCameraTo(
      lat: _centerLat,
      lng: _centerLng,
      targetZoom: (_zoom + delta).clamp(10.5, 17.5),
    );
  }

  void _recenterToUserGps() {
    HapticFeedback.lightImpact();
    _animateCameraTo(
      lat: MapConfig.userGpsLat,
      lng: MapConfig.userGpsLng,
      targetZoom: 13.2,
    );
  }

  void _resetOverview() {
    HapticFeedback.lightImpact();
    _animateCameraTo(
      lat: MapConfig.initialCenterLat,
      lng: MapConfig.initialCenterLng,
      targetZoom: MapConfig.initialZoom,
    );
  }

  /// Titik fokus visual di bagian atas layar (di atas Bottom Sheet 50%)
  Offset _focalPoint(BoxConstraints constraints) {
    return Offset(constraints.maxWidth * 0.50, constraints.maxHeight * 0.28);
  }

  /// Mengubah koordinat (lat, lng) menjadi titik piksel di layar
  Offset _latLngToScreen(
    double lat,
    double lng,
    BoxConstraints constraints,
  ) {
    final focal = _focalPoint(constraints);
    final centerWorld =
        InteractiveMapCanvas.latLngToWorldPixel(_centerLat, _centerLng, _zoom);
    final pointWorld = InteractiveMapCanvas.latLngToWorldPixel(lat, lng, _zoom);
    return focal + (pointWorld - centerWorld);
  }

  /// Menghindari tumpukan jika laporan baru menggunakan koordinat default yang sama persis
  (double, double) _effectiveReportLatLng(CitizenReport report) {
    if (report.id == 'rep-001' ||
        report.id == 'rep-002' ||
        report.id == 'rep-003') {
      return (report.latitude, report.longitude);
    }
    final hash = report.id.hashCode;
    final latJitter = ((hash % 100) / 100.0 - 0.5) * 0.012;
    final lngJitter = (((hash ~/ 100) % 100) / 100.0 - 0.5) * 0.012;
    return (report.latitude + latJitter, report.longitude + lngJitter);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final focal = _focalPoint(constraints);
        final userGpsScreen = _latLngToScreen(
          MapConfig.userGpsLat,
          MapConfig.userGpsLng,
          constraints,
        );

        return ClipRect(
          child: Stack(
            children: [
              // 1. Geographically Projected Fallback Vector Canvas (Sungai Ciliwung & Jalan Utama DKI Jakarta)
              // Selalu tampil mulus saat tile sedang dimuat atau saat mode offline / flutter test
              Positioned.fill(
                child: CustomPaint(
                  painter: _JakartaGeoVectorPainter(
                    centerLat: _centerLat,
                    centerLng: _centerLng,
                    zoom: _zoom,
                    focalPoint: focal,
                    layerStyle: _layerStyle,
                  ),
                ),
              ),

              // 2. Real Slippy Map Tile Grid (Google Maps / CartoDB Light / Google Hybrid)
              ..._buildVisibleTiles(constraints, focal),

              // 3. Area Interaksi Geser & Cubit Peta di Bagian Atas (di atas Bottom Sheet)
              // Menyesuaikan tinggi area peta secara dinamis ketika Bottom Sheet diciutkan (0.18)
              // maupun saat setengah layar (0.50 -> 48% atas layar) agar swipe PageView tetap mulus
              Positioned(
                key: const ValueKey('map-gesture-viewport'),
                top: 0,
                left: 0,
                right: 0,
                height: (1.0 - widget.bottomSheetExtent - 0.02)
                        .clamp(0.10, 0.82) *
                    constraints.maxHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onScaleStart: (details) {
                    _cameraController.stop();
                    _lastFocalPoint = details.localFocalPoint;
                    _scaleStartZoom = _zoom;
                  },
                  onScaleUpdate: (details) {
                    if (_lastFocalPoint == null) return;
                    final delta = details.localFocalPoint - _lastFocalPoint!;
                    _lastFocalPoint = details.localFocalPoint;

                    setState(() {
                      if (_scaleStartZoom != null &&
                          details.scale > 0.0 &&
                          (details.pointerCount >= 2 ||
                              (details.scale - 1.0).abs() > 1e-4)) {
                        _zoom = (_scaleStartZoom! +
                                math.log(details.scale) / math.ln2)
                            .clamp(10.5, 17.5);
                      }
                      final centerWorld =
                          InteractiveMapCanvas.latLngToWorldPixel(
                        _centerLat,
                        _centerLng,
                        _zoom,
                      );
                      final updated =
                          InteractiveMapCanvas.worldPixelToLatLng(
                        centerWorld.dx - delta.dx,
                        centerWorld.dy - delta.dy,
                        _zoom,
                      );
                      _centerLat = updated.$1.clamp(-6.45, -6.00);
                      _centerLng = updated.$2.clamp(106.60, 107.05);
                    });
                  },
                  onDoubleTap: () => _zoomBy(1.0),
                ),
              ),

              // 4. Pin Stasiun Pemantau Wilayah Sekitar (Tidak Terpilih)
              ...widget.stations
                  .where((st) => widget.selectedStation?.id != st.id)
                  .map((st) => _buildStationPinWidget(st, constraints)),

              // 5. Pin Laporan Warga di Sekitar (Tidak Terpilih)
              ...widget.citizenReports
                  .where((r) => widget.selectedReport?.id != r.id)
                  .map((r) => _buildReportPinWidget(r, constraints)),

              // 6. Titik Biru Berdenyut GPS Pengguna (Bantaran Ciliwung: -6.2250, 106.8600)
              Positioned(
                left: userGpsScreen.dx - 58,
                top: userGpsScreen.dy - 36,
                child: GestureDetector(
                  key: const ValueKey('user-gps-pin'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _recenterToUserGps,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [AppColors.softGlow],
                          border: Border.all(
                            color: const Color(0xFF38BDF8),
                            width: 1.2,
                          ),
                        ),
                        child: const Text(
                          'GPS Anda (Ciliwung)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const PulsingDot(
                        color: Color(0xFF0284C7),
                        size: 10,
                        pulseRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),

              // 7. Pin Stasiun / Laporan Warga yang Sedang Dipilih (Selalu di Atas Z-Order)
              ...widget.stations
                  .where((st) => widget.selectedStation?.id == st.id)
                  .map((st) => _buildStationPinWidget(st, constraints)),
              ...widget.citizenReports
                  .where((r) => widget.selectedReport?.id == r.id)
                  .map((r) => _buildReportPinWidget(r, constraints)),

              // 7. Kontrol Layer Peta (Google Maps / Nordic Light / Satelit) & Navigasi Zoom/GPS
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 70, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge Sumber Peta & Koordinat Aktif
                          Flexible(
                            child: GestureDetector(
                              key: const ValueKey('map-reset-overview-badge'),
                              onTap: _resetOverview,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: const [AppColors.softGlow],
                                  border: Border.all(
                                    color: const Color(0x14000000),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.public_rounded,
                                      size: 13,
                                      color: Color(0xFF0284C7),
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        MapConfig.styleSourceBadge(_layerStyle),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Tombol Switch Layer Peta (Google Maps <-> Nordic Light <-> Satelit)
                          GestureDetector(
                            key: const ValueKey('map-layer-switch-button'),
                            onTap: _cycleMapLayer,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.textPrimary,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [AppColors.softGlow],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.layers_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    MapConfig.styleLabel(_layerStyle),
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Tombol Zoom In, Zoom Out, dan Pusatkan ke GPS Pengguna
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [AppColors.softGlow],
                          border: Border.all(
                            color: const Color(0x14000000),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _mapControlIconButton(
                              key: const ValueKey('map-zoom-in-button'),
                              icon: Icons.add_rounded,
                              tooltip: 'Perbesar Peta',
                              onTap: () => _zoomBy(1.0),
                            ),
                            Container(
                              width: 24,
                              height: 1,
                              color: const Color(0xFFE2E8F0),
                            ),
                            _mapControlIconButton(
                              key: const ValueKey('map-zoom-out-button'),
                              icon: Icons.remove_rounded,
                              tooltip: 'Perkecil Peta',
                              onTap: () => _zoomBy(-1.0),
                            ),
                            Container(
                              width: 24,
                              height: 1,
                              color: const Color(0xFFE2E8F0),
                            ),
                            _mapControlIconButton(
                              key: const ValueKey('map-gps-center-button'),
                              icon: Icons.my_location_rounded,
                              iconColor: const Color(0xFF0284C7),
                              tooltip: 'Pusatkan ke GPS Anda',
                              onTap: _recenterToUserGps,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStationPinWidget(
    StationNode st,
    BoxConstraints constraints,
  ) {
    final pos = _latLngToScreen(
      st.latitude,
      st.longitude,
      constraints,
    );
    final isSelected = widget.selectedStation?.id == st.id;
    final isWaspada = st.overallStatus == 'Waspada';
    // Untuk stasiun di selatan titik GPS pengguna (seperti Jakarta Timur -6.2320),
    // letakkan ikon di atas label agar tidak menutupi pin GPS Anda (-6.2250) pada zoom awal.
    final labelBelowIcon = st.latitude < -6.228;

    final labelPill = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.textPrimary : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [AppColors.softGlow],
        border: Border.all(
          color: isWaspada
              ? AppColors.statusWarningText
              : AppColors.litosferEmerald,
          width: 1.2,
        ),
      ),
      child: Text(
        '${st.name} (${st.distanceKm}km)',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );

    final pinIcon = Icon(
      Icons.location_on_rounded,
      size: isSelected ? 28 : 22,
      color: isWaspada ? AppColors.statusWarningText : AppColors.litosferEmerald,
    );

    return Positioned(
      left: pos.dx - 52,
      top: labelBelowIcon ? pos.dy - 10 : pos.dy - 38,
      child: GestureDetector(
        key: ValueKey('map-station-pin-${st.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _animateCameraTo(
            lat: st.latitude,
            lng: st.longitude,
            targetZoom: math.max(_zoom, 13.2),
          );
          widget.onSelectStation(st);
        },
        child: AnimatedScale(
          scale: isSelected ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: labelBelowIcon
                ? [pinIcon, const SizedBox(height: 2), labelPill]
                : [labelPill, const SizedBox(height: 2), pinIcon],
          ),
        ),
      ),
    );
  }

  Widget _buildReportPinWidget(
    CitizenReport report,
    BoxConstraints constraints,
  ) {
    final coords = _effectiveReportLatLng(report);
    final pos = _latLngToScreen(
      coords.$1,
      coords.$2,
      constraints,
    );
    final isSelected = widget.selectedReport?.id == report.id;

    return Positioned(
      left: pos.dx - 40,
      top: pos.dy - 32,
      child: GestureDetector(
        key: ValueKey('map-report-pin-${report.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _animateCameraTo(
            lat: coords.$1,
            lng: coords.$2,
            targetZoom: math.max(_zoom, 13.6),
          );
          widget.onSelectReport?.call(report);
        },
        child: AnimatedScale(
          scale: isSelected ? 1.18 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.blockchainIndigo
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [AppColors.softGlow],
                  border: Border.all(
                    color: isSelected
                        ? AppColors.blockchainIndigo
                        : const Color(0xFFFCA5A5),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.campaign_rounded,
                      size: 10,
                      color: isSelected
                          ? Colors.white
                          : AppColors.statusDangerText,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _shortCategory(report.category),
                      style: TextStyle(
                        fontSize: 9.0,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : AppColors.statusDangerText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Icon(
                Icons.warning_amber_rounded,
                size: isSelected ? 26 : 20,
                color: isSelected
                    ? AppColors.blockchainIndigo
                    : AppColors.statusDangerText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapControlIconButton({
    required Key key,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color iconColor = AppColors.textPrimary,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Icon(
          icon,
          size: 16,
          color: iconColor,
        ),
      ),
    );
  }

  /// Membangun daftar tile peta Web Mercator yang terlihat di layar saat ini
  List<Widget> _buildVisibleTiles(
    BoxConstraints constraints,
    Offset focal,
  ) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    if (w <= 0 || h <= 0) return const [];

    final tileZ = _zoom.round().clamp(10, 18);
    final tileScale = math.pow(2.0, _zoom - tileZ).toDouble();
    final tileDisplaySize = 256.0 * tileScale;

    final centerWorldAtTileZ = InteractiveMapCanvas.latLngToWorldPixel(
      _centerLat,
      _centerLng,
      tileZ.toDouble(),
    );
    final centerScaledX = centerWorldAtTileZ.dx * tileScale;
    final centerScaledY = centerWorldAtTileZ.dy * tileScale;

    final leftWorldX = centerScaledX - focal.dx;
    final rightWorldX = centerScaledX + (w - focal.dx);
    final topWorldY = centerScaledY - focal.dy;
    final bottomWorldY = centerScaledY + (h - focal.dy);

    final minTx = (leftWorldX / tileDisplaySize).floor();
    final maxTx = (rightWorldX / tileDisplaySize).floor();
    final minTy = (topWorldY / tileDisplaySize).floor();
    final maxTy = (bottomWorldY / tileDisplaySize).floor();

    final List<Widget> tiles = [];
    for (int ty = minTy; ty <= maxTy; ty++) {
      for (int tx = minTx; tx <= maxTx; tx++) {
        final screenLeft = focal.dx + (tx * tileDisplaySize - centerScaledX);
        final screenTop = focal.dy + (ty * tileDisplaySize - centerScaledY);
        final url = MapConfig.resolveTileUrl(
          style: _layerStyle,
          z: tileZ,
          x: tx,
          y: ty,
        );

        tiles.add(
          Positioned(
            key: ValueKey('tile-${_layerStyle.name}-$tileZ-$tx-$ty'),
            left: screenLeft,
            top: screenTop,
            width: tileDisplaySize + 0.6,
            height: tileDisplaySize + 0.6,
            child: Image.network(
              url,
              headers: MapConfig.tileRequestHeaders,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              // Silent fallback handler: saat dijalankan di flutter test (HTTP 400)
              // atau ketika perangkat sedang offline, tidak melempar exception
              // dan membiarkan peta vektor geografis Jakarta di bawahnya tampil bersih.
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        );
      }
    }
    return tiles;
  }

  String _shortCategory(String full) {
    if (full.contains('Keruh')) return 'Air Keruh';
    if (full.contains('Retakan')) return 'Retakan';
    if (full.contains('Tumbang')) return 'Pohon';
    return 'Laporan';
  }
}

/// Painter Vektor Geografis DKI Jakarta & Aliran Sungai Ciliwung berbasis Web Mercator
/// Berfungsi sebagai base map instan (0ms latency) sekaligus fallback offline / test
class _JakartaGeoVectorPainter extends CustomPainter {
  final double centerLat;
  final double centerLng;
  final double zoom;
  final Offset focalPoint;
  final MapTileStyle layerStyle;

  _JakartaGeoVectorPainter({
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
    required this.focalPoint,
    required this.layerStyle,
  });

  Offset _toScreen(double lat, double lng) {
    final centerWorld =
        InteractiveMapCanvas.latLngToWorldPixel(centerLat, centerLng, zoom);
    final ptWorld = InteractiveMapCanvas.latLngToWorldPixel(lat, lng, zoom);
    return focalPoint + (ptWorld - centerWorld);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final isDarkHybrid = layerStyle == MapTileStyle.googleHybrid;
    final isGoogleStandard = layerStyle == MapTileStyle.googleStandard;

    // 1. Latar Daratan DKI Jakarta
    final landColor = isDarkHybrid
        ? const Color(0xFF1E293B)
        : isGoogleStandard
            ? const Color(0xFFF3F4F6)
            : const Color(0xFFF1F5F9);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = landColor,
    );

    // 2. Perairan Laut Teluk Jakarta di Utara (sekitar lat > -6.115)
    final seaBoundary = _toScreen(-6.1120, 106.8350);
    if (seaBoundary.dy > 0) {
      final seaPaint = Paint()
        ..color = isDarkHybrid
            ? const Color(0xFF0F172A)
            : isGoogleStandard
                ? const Color(0xFFAADAFF)
                : const Color(0xFFBAE6FD)
        ..style = PaintingStyle.fill;
      final seaPath = Path()
        ..moveTo(0, 0)
        ..lineTo(w, 0)
        ..lineTo(w, seaBoundary.dy)
        ..quadraticBezierTo(
          w * 0.5,
          seaBoundary.dy + 18,
          0,
          seaBoundary.dy - 10,
        )
        ..close();
      canvas.drawPath(seaPath, seaPaint);
    }

    // 3. Area Ruang Terbuka Hijau (Monas, Hutan Kota Tebet, Ragunan/Timur)
    final parkPaint = Paint()
      ..color = isDarkHybrid
          ? const Color(0xFF064E3B).withValues(alpha: 0.55)
          : isGoogleStandard
              ? const Color(0xFFC8E6C9)
              : const Color(0xFFE2F7ED)
      ..style = PaintingStyle.fill;

    // Taman Monas (Jakarta Pusat)
    final monasCenter = _toScreen(-6.1754, 106.8272);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: monasCenter, width: 42, height: 42),
        const Radius.circular(12),
      ),
      parkPaint,
    );

    // Taman Tebet / Manggarai
    final tebetPark = _toScreen(-6.2280, 106.8510);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: tebetPark, width: 56, height: 36),
        const Radius.circular(14),
      ),
      parkPaint,
    );

    // 4. Jaringan Jalan Arteri Utama DKI Jakarta (Sudirman-Thamrin, Gatot Subroto, Tol Dalam Kota)
    final roadBorderPaint = Paint()
      ..color = isDarkHybrid
          ? const Color(0xFF475569)
          : isGoogleStandard
              ? const Color(0xFFFDE68A)
              : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final roadCorePaint = Paint()
      ..color = isDarkHybrid
          ? const Color(0xFF64748B)
          : isGoogleStandard
              ? const Color(0xFFFEF08A)
              : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Koridor Tol Dalam Kota: Tomang (Jakbar) -> Semanggi -> Tebet -> Cawang (Jaktim)
    final innerRingRoad = <Offset>[
      _toScreen(-6.1780, 106.7950),
      _toScreen(-6.2050, 106.8050),
      _toScreen(-6.2220, 106.8200),
      _toScreen(-6.2380, 106.8450),
      _toScreen(-6.2440, 106.8750),
    ];
    _drawPolyline(canvas, innerRingRoad, roadBorderPaint);
    _drawPolyline(canvas, innerRingRoad, roadCorePaint);

    // Koridor Sudirman - Thamrin - Kota -> Ancol (Utara - Selatan)
    final northSouthArterial = <Offset>[
      _toScreen(-6.1280, 106.8350),
      _toScreen(-6.1750, 106.8230),
      _toScreen(-6.2000, 106.8230),
      _toScreen(-6.2250, 106.8150),
      _toScreen(-6.2600, 106.8100),
    ];
    _drawPolyline(canvas, northSouthArterial, roadBorderPaint);
    _drawPolyline(canvas, northSouthArterial, roadCorePaint);

    // Koridor Jatinegara - Kampung Melayu - Salemba - Senen
    final eastCentralArterial = <Offset>[
      _toScreen(-6.2450, 106.8680),
      _toScreen(-6.2250, 106.8660),
      _toScreen(-6.1950, 106.8500),
      _toScreen(-6.1750, 106.8420),
    ];
    _drawPolyline(canvas, eastCentralArterial, roadBorderPaint);
    _drawPolyline(canvas, eastCentralArterial, roadCorePaint);

    // 5. Aliran Nyata Sungai Ciliwung (Condet -> Cawang -> Kampung Melayu -> Manggarai -> Menteng -> Ancol)
    final riverGlowPaint = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final riverCorePaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final ciliwungCoords = <Offset>[
      _toScreen(-6.2750, 106.8550), // Kalibata / Condet
      _toScreen(-6.2450, 106.8630), // Bidara Cina / Cawang
      _toScreen(-6.2320, 106.8640), // Kampung Melayu
      _toScreen(-6.2250, 106.8600), // Titik GPS Pengguna (Bantaran Ciliwung)
      _toScreen(-6.2150, 106.8480), // Tebet / Pintu Air Manggarai
      _toScreen(-6.1980, 106.8380), // Cikini / Menteng
      _toScreen(-6.1680, 106.8320), // Pasar Baru / Gunung Sahari
      _toScreen(-6.1280, 106.8350), // Muara Ancol / Teluk Jakarta
    ];

    _drawPolyline(canvas, ciliwungCoords, riverGlowPaint);
    _drawPolyline(canvas, ciliwungCoords, riverCorePaint);

    // Label Aliran Sungai Ciliwung
    final riverLabelPos = _toScreen(-6.2290, 106.8620);
    final riverText = TextPainter(
      text: TextSpan(
        text: 'ALIRAN SUNGAI CILIWUNG',
        style: TextStyle(
          color: isDarkHybrid
              ? const Color(0xFF38BDF8)
              : const Color(0xFF0369A1),
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    riverText.paint(canvas, riverLabelPos + const Offset(10, 4));
  }

  void _drawPolyline(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _JakartaGeoVectorPainter oldDelegate) {
    return oldDelegate.centerLat != centerLat ||
        oldDelegate.centerLng != centerLng ||
        oldDelegate.zoom != zoom ||
        oldDelegate.focalPoint != focalPoint ||
        oldDelegate.layerStyle != layerStyle;
  }
}
