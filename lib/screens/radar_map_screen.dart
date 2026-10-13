import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../models/station_node.dart';
import '../models/citizen_report.dart';
import '../services/mock_data_service.dart';
import '../widgets/interactive_map_canvas.dart';
import '../widgets/tactile_card.dart';
import '../widgets/status_badge.dart';

/// Layar 3: Radar Peta & Wilayah Sekitar
/// Dilengkapi peta interaktif, floating search bar, dan Draggable Bottom Sheet
/// dengan 3 snap points (0.18, 0.50, 0.90) berbasis spring physics
/// Menampilkan pos pantau wilayah sekitar dan laporan warga terverifikasi
class RadarMapScreen extends StatefulWidget {
  const RadarMapScreen({super.key});

  @override
  State<RadarMapScreen> createState() => _RadarMapScreenState();
}

class _RadarMapScreenState extends State<RadarMapScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<StationNode> _allStations = MockDataService.surroundingStations;
  List<StationNode> _filteredStations = [];
  List<CitizenReport> _filteredReports = [];

  StationNode? _selectedStation;
  CitizenReport? _selectedReport;
  int _selectedTab = 0; // 0: Pos Pantau, 1: Laporan Warga
  int _focusTrigger = 0;
  double _sheetExtent = 0.50;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _filteredStations = _allStations;
    _filteredReports = MockDataService.citizenReports;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshReports();
  }

  void _refreshReports() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredReports = MockDataService.citizenReports;
      } else {
        _filteredReports = MockDataService.citizenReports
            .where((r) =>
                r.category.toLowerCase().contains(query) ||
                r.description.toLowerCase().contains(query) ||
                r.locationName.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredStations = _allStations;
        _filteredReports = MockDataService.citizenReports;
      } else {
        _filteredStations = _allStations
            .where((st) =>
                st.name.toLowerCase().contains(q) ||
                st.weatherCondition.toLowerCase().contains(q))
            .toList();
        _filteredReports = MockDataService.citizenReports
            .where((r) =>
                r.category.toLowerCase().contains(q) ||
                r.description.toLowerCase().contains(q) ||
                r.locationName.toLowerCase().contains(q))
            .toList();

        // Switch to the tab with matches if currently empty
        if (_filteredStations.isEmpty && _filteredReports.isNotEmpty) {
          _selectedTab = 1;
        } else if (_filteredReports.isEmpty && _filteredStations.isNotEmpty) {
          _selectedTab = 0;
        }
      }
    });
  }

  void _onSelectStation(StationNode st) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedStation = st;
      _selectedReport = null;
      _selectedTab = 0;
      _focusTrigger++;
    });

    _expandSheetIfNeeded();
  }

  void _onSelectReport(CitizenReport report) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedReport = report;
      _selectedStation = null;
      _selectedTab = 1;
      _focusTrigger++;
    });

    _expandSheetIfNeeded();
  }

  void _expandSheetIfNeeded() {
    if (_sheetController.isAttached && _sheetController.size < 0.35) {
      _sheetController.animateTo(
        0.50,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showReportDetailModal(BuildContext context, CitizenReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.blockchainIndigoBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.campaign_rounded,
                          color: AppColors.blockchainIndigo,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.category,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            report.locationName,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  StatusBadge(
                    label: report.statusText,
                    type: report.isVerified ? BadgeType.safe : BadgeType.warning,
                    fontSize: 11,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  report.description,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Bukti SHA-256 On-Chain
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.blockchainIndigoBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.blockchainIndigoBorder,
                    width: 0.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: AppColors.blockchainIndigo,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Kunci Bukti Blockchain (SHA-256 Valid)',
                          style: TextStyle(
                            color: AppColors.blockchainIndigo,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      report.sha256Hash,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Tutup Detail'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          // 1. Peta Interaktif (Top Canvas) dengan stasiun dan laporan warga
          Positioned.fill(
            child: InteractiveMapCanvas(
              stations: _filteredStations,
              selectedStation: _selectedStation,
              onSelectStation: _onSelectStation,
              citizenReports: _filteredReports,
              selectedReport: _selectedReport,
              onSelectReport: _onSelectReport,
              focusTrigger: _focusTrigger,
              bottomSheetExtent: _sheetExtent,
            ),
          ),

          // 2. Floating Search Bar di Atas
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [AppColors.floatingShadow],
                  border: Border.all(
                    color: const Color(0x0F000000),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari wilayah / pos pantau...',
                    hintStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            color: AppColors.textSecondary,
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Bottom Sheet "Kondisi Wilayah Sekitar (Radius 10 km)"
          // 3 Snap Points: 0.18 (Peek), 0.50 (Half), 0.90 (Full)
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              if ((_sheetExtent - notification.extent).abs() > 0.005) {
                setState(() {
                  _sheetExtent = notification.extent;
                });
              }
              return false;
            },
            child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.50,
              minChildSize: 0.18,
              maxChildSize: 0.90,
              snap: true,
              snapSizes: const [0.18, 0.50, 0.90],
              builder: (context, scrollController) {
                return Container(
                decoration: const BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [AppColors.floatingShadow],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Header Sheet (Kondisi Wilayah Sekitar)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kondisi Wilayah Sekitar',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Radius 10 km dari Bantaran Ciliwung',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_filteredStations.length} Pos • ${_filteredReports.length} Laporan',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Segmented Filter Tabs: Pos Pantau & Laporan Warga
                    Row(
                      children: [
                        Expanded(
                          child: _segmentTab(
                            title: 'Pos Pantau (${_filteredStations.length})',
                            isSelected: _selectedTab == 0,
                            icon: Icons.cell_tower_rounded,
                            onTap: () => setState(() => _selectedTab = 0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _segmentTab(
                            title: 'Laporan Warga (${_filteredReports.length})',
                            isSelected: _selectedTab == 1,
                            icon: Icons.campaign_rounded,
                            onTap: () => setState(() => _selectedTab = 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Content based on selected tab
                    if (_selectedTab == 0) ...[
                      if (_filteredStations.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Tidak ada pos pantau yang cocok dengan pencarian.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._filteredStations.map(
                          (station) => _buildStationCard(station),
                        ),
                    ] else ...[
                      if (_filteredReports.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Tidak ada laporan warga yang cocok dengan pencarian.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._filteredReports.map(
                          (report) => _buildCitizenReportCard(report),
                        ),
                    ],
                  ],
                ),
              );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentTab({
    required String title,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationCard(StationNode station) {
    final isSelected = _selectedStation?.id == station.id;
    final isWaspada = station.overallStatus == 'Waspada';

    return TactileCard(
      onTap: () => _onSelectStation(station),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      border: Border.all(
        color: isSelected
            ? AppColors.textPrimary
            : isWaspada
                ? const Color(0xFFFDE68A)
                : const Color(0x0F000000),
        width: isSelected ? 1.5 : 1.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isWaspada
                            ? AppColors.statusWarningBg
                            : AppColors.statusSafeBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isWaspada
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 16,
                        color: isWaspada
                            ? AppColors.statusWarningText
                            : AppColors.statusSafeText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${station.name} (${station.distanceKm} km)',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: station.overallStatus,
                type: isWaspada ? BadgeType.warning : BadgeType.safe,
                fontSize: 11,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Cuaca & Suhu
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        station.weatherCondition == 'Cerah'
                            ? Icons.wb_sunny_outlined
                            : station.weatherCondition == 'Angin'
                                ? Icons.air_rounded
                                : Icons.cloud_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${station.weatherCondition} ${station.temperature.toInt()}°C',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Status Daya & Sensor Stasiun Lingkungan
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.solar_power_outlined,
                        size: 16,
                        color: AppColors.litosferEmerald,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Solar ${station.solarLevel}% Aktif',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCitizenReportCard(CitizenReport report) {
    final isSelected = _selectedReport?.id == report.id;

    return TactileCard(
      onTap: () {
        _onSelectReport(report);
        _showReportDetailModal(context, report);
      },
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      border: Border.all(
        color: isSelected ? AppColors.blockchainIndigo : const Color(0x0F000000),
        width: isSelected ? 1.5 : 1.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.blockchainIndigoBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        size: 16,
                        color: AppColors.blockchainIndigo,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        report.category,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: report.statusText,
                type: report.isVerified ? BadgeType.safe : BadgeType.warning,
                fontSize: 11,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.description,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        report.locationName,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.blockchainIndigoBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Kunci On-Chain Valid',
                  style: TextStyle(
                    color: AppColors.blockchainIndigo,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
