import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/habitat_data.dart';
import '../services/arduino_sensor_service.dart';
import '../services/mock_data_service.dart';
import '../widgets/tactile_card.dart';
import '../widgets/pulsing_dot.dart';
import '../widgets/weather_illustration.dart';
import '../widgets/humidity_capsule_gauge.dart';
import '../widgets/soil_radial_gauge.dart';
import '../widgets/sepolia_proof_card.dart';
import 'conditions_detail_sheet.dart';

class HomeDashboardScreen extends StatefulWidget {
  final VoidCallback? onOpenMenu;
  final ValueChanged<int>? onNavigateToPage;
  final DateTime? currentDateTime;

  const HomeDashboardScreen({
    super.key,
    this.onOpenMenu,
    this.onNavigateToPage,
    this.currentDateTime,
  });

  /// Menghasilkan salam Bahasa Indonesia sesuai jam perangkat saat ini.
  static String formatGreeting(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour >= 4 && hour < 11) {
      return 'selamat pagi,';
    } else if (hour >= 11 && hour < 15) {
      return 'selamat siang,';
    } else if (hour >= 15 && hour < 18) {
      return 'selamat sore,';
    } else {
      return 'selamat malam,';
    }
  }

  /// Menghasilkan format `<HARI> <TANGGAL> <BULAN> <TAHUN>` huruf kapital
  /// dalam Bahasa Indonesia (contoh: `SELASA 13 OKTOBER 2026`).
  static String formatIndonesianDate(DateTime dateTime) {
    const dayNames = <int, String>{
      DateTime.monday: 'SENIN',
      DateTime.tuesday: 'SELASA',
      DateTime.wednesday: 'RABU',
      DateTime.thursday: 'KAMIS',
      DateTime.friday: 'JUMAT',
      DateTime.saturday: 'SABTU',
      DateTime.sunday: 'MINGGU',
    };

    const monthNames = <int, String>{
      1: 'JANUARI',
      2: 'FEBRUARI',
      3: 'MARET',
      4: 'APRIL',
      5: 'MEI',
      6: 'JUNI',
      7: 'JULI',
      8: 'AGUSTUS',
      9: 'SEPTEMBER',
      10: 'OKTOBER',
      11: 'NOVEMBER',
      12: 'DESEMBER',
    };

    final dayName = dayNames[dateTime.weekday] ?? 'SENIN';
    final monthName = monthNames[dateTime.month] ?? 'JANUARI';
    return '$dayName ${dateTime.day} $monthName ${dateTime.year}';
  }

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  AtmosferData get atmosfer => ArduinoSensorService.currentAtmosfer;
  LitosferData get litosfer => ArduinoSensorService.currentLitosfer;
  final BlockchainProof blockchainProof = MockDataService.currentBlockchainProof;

  void _onSensorUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    ArduinoSensorService.litosferNotifier.addListener(_onSensorUpdated);
    ArduinoSensorService.atmosferNotifier.addListener(_onSensorUpdated);
    ArduinoSensorService.startPolling();
  }

  @override
  void dispose() {
    ArduinoSensorService.litosferNotifier.removeListener(_onSensorUpdated);
    ArduinoSensorService.atmosferNotifier.removeListener(_onSensorUpdated);
    ArduinoSensorService.stopPolling();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // ==========================================
              // 1. Top Navigation Bar (Minimalis)
              // ==========================================
              _buildTopNavBar(),

              const SizedBox(height: 28),

              // ==========================================
              // 2. Hero Weather Display (Nordic Ultra-Clean)
              // Sesuai Referensi 2: lapang, bernapas, zero clutter
              // ==========================================
              _buildHeroWeatherDisplay(),

              const SizedBox(height: 36),

              // ==========================================
              // Section Header: Rincian Kondisi Lingkungan
              // ==========================================
              _buildConditionsSectionHeader(),

              const SizedBox(height: 16),

              // ==========================================
              // 3. Micro-Condition Cards (Referensi 3: Bento Grid 2 Kolom)
              // Atmosfer (Kelembapan) & Litosfer (Tanah)
              // ==========================================
              _buildMicroConditionsGrid(),

              const SizedBox(height: 18),

              // ==========================================
              // 4. Integritas On-Chain Sepolia (Slim Trust Card)
              // ==========================================
              SepoliaProofCard(proof: blockchainProof),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Top Navigation Bar (Minimalis)
  Widget _buildTopNavBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Ikon menu garis halus
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onOpenMenu ?? () => _showAboutModal(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Icon(
              Icons.menu_rounded,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Label lokasi registrasi
        const Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 15,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Bantaran Ciliwung, Jkt',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),

        // Status indikator stasiun (lingkaran kecil berdenyut hijau)
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              boxShadow: const [AppColors.softGlow],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PulsingDot(
                  color: AppColors.litosferEmerald,
                  size: 5,
                  pulseRadius: 8,
                ),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Solar 94% • Real-Time',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 2. Hero Weather Display (Nordic Ultra-Clean & Spacious)
  Widget _buildHeroWeatherDisplay() {
    final now = widget.currentDateTime ?? DateTime.now();
    final greetingText = HomeDashboardScreen.formatGreeting(now);
    final dateText = HomeDashboardScreen.formatIndonesianDate(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Ilustrasi garis vektor minimalis dengan bulatan warna pastel
        const WeatherIllustration(size: 130),

        const SizedBox(height: 22),

        // Suhu besar elegan Nordic (tetap dummy sesuai kebutuhan saat ini)
        Text(
          '${atmosfer.temperature.toInt()}°',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 84,
            fontWeight: FontWeight.w700,
            height: 0.95,
            letterSpacing: -4.0,
          ),
        ),

        const SizedBox(height: 6),

        // Terasa seperti 30°
        Text(
          'Terasa seperti ${atmosfer.feelsLike.toInt()}°',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 24),

        // Salam & Hari bergaya Nordic editorial mengikuti waktu sekarang
        Text(
          greetingText,
          key: const ValueKey('hero-greeting-text'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 18,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateText,
          key: const ValueKey('hero-date-text'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 18),

        // Status Ringkas Lingkungan: "🍃 Kondisi Aman • Udara Bersih"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.statusSafeBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
          ),
          child: const Text(
            '🍃  Kondisi Aman • Udara Bersih',
            style: TextStyle(
              color: AppColors.statusSafeText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }

  // Section Header: Kondisi Lingkungan Aktual
  Widget _buildConditionsSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Text(
            'Kondisi Lingkungan Aktual',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Sensori Real-Time',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // 3. Micro-Condition Cards (Referensi 3: Bento Grid 2 Kolom)
  Widget _buildMicroConditionsGrid() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kartu 1: Atmosfer (Kelembapan & Sirkulasi Udara)
          Expanded(
            child: Container(
              key: const ValueKey('bento-atmosfer-card'),
              child: _buildAtmosferBentoCard(),
            ),
          ),
          const SizedBox(width: 14),

          // Kartu 2: Litosfer (Tanah & Lereng)
          Expanded(
            child: Container(
              key: const ValueKey('bento-litosfer-card'),
              child: _buildLitosferBentoCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtmosferBentoCard() {
    return TactileCard(
      onTap: () => ConditionsDetailSheet.show(
        context,
        type: HabitatType.atmosfer,
        atmosfer: atmosfer,
        litosfer: litosfer,
      ),
      backgroundColor: Colors.white,
      border: Border.all(color: const Color(0x14000000), width: 1.0),
      shadows: const [
        BoxShadow(
          color: Color(0x06000000),
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ],
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.atmosferSky.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.air_rounded,
                  color: AppColors.atmosferSky,
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Kelembapan',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: SizedBox(
              height: 90,
              child: Center(
                child: HumidityCapsuleGauge(
                  humidityPercent: atmosfer.humidity,
                  width: 40,
                  height: 90,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${atmosfer.humidity}%',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Atmosfer (Sirkulasi Udara)',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Normal • ${atmosfer.pressure} hPa',
                style: const TextStyle(
                  color: AppColors.statusSafeText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLitosferBentoCard() {
    return TactileCard(
      onTap: () => ConditionsDetailSheet.show(
        context,
        type: HabitatType.litosfer,
        atmosfer: atmosfer,
        litosfer: litosfer,
      ),
      backgroundColor: Colors.white,
      border: Border.all(color: const Color(0x14000000), width: 1.0),
      shadows: const [
        BoxShadow(
          color: Color(0x06000000),
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ],
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.litosferEmerald.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.landscape_rounded,
                  color: AppColors.litosferEmerald,
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Tanah',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: SizedBox(
              height: 90,
              child: Center(
                child: SoilRadialGauge(
                  soilPercent: litosfer.soilMoisture,
                  size: 90,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${litosfer.soilMoisture}%',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Litosfer (Kelembapan Tanah)',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Stabil • Risiko ${litosfer.landslideRisk}',
                style: const TextStyle(
                  color: AppColors.statusSafeText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAboutModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 20),
            const Text(
              'T.H.A.L.I.A',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tri-Habitat Analysis & Climate Forecasting Intelligence',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'HackSphere 2026 - Tim Ayam Kecap Paijo\nPoliteknik Astra (ASTRA Polytechnic)',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
