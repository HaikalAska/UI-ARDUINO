import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/habitat_data.dart';
import '../services/arduino_sensor_service.dart';
import '../widgets/status_badge.dart';
import '../widgets/humidity_capsule_gauge.dart';
import '../widgets/soil_radial_gauge.dart';

enum HabitatType { atmosfer, litosfer }

class ConditionsDetailSheet extends StatefulWidget {
  final HabitatType type;
  final AtmosferData atmosfer;
  final LitosferData litosfer;

  const ConditionsDetailSheet({
    super.key,
    required this.type,
    required this.atmosfer,
    required this.litosfer,
  });

  static void show(
    BuildContext context, {
    required HabitatType type,
    required AtmosferData atmosfer,
    required LitosferData litosfer,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConditionsDetailSheet(
        type: type,
        atmosfer: atmosfer,
        litosfer: litosfer,
      ),
    );
  }

  @override
  State<ConditionsDetailSheet> createState() => _ConditionsDetailSheetState();
}

class _ConditionsDetailSheetState extends State<ConditionsDetailSheet> {
  late AtmosferData _atmosfer;
  late LitosferData _litosfer;

  void _onAtmosferChanged() {
    if (mounted) {
      setState(() {
        _atmosfer = ArduinoSensorService.currentAtmosfer;
      });
    }
  }

  void _onLitosferChanged() {
    if (mounted) {
      setState(() {
        _litosfer = ArduinoSensorService.currentLitosfer;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _atmosfer = widget.atmosfer;
    _litosfer = widget.litosfer;
    ArduinoSensorService.atmosferNotifier.addListener(_onAtmosferChanged);
    ArduinoSensorService.litosferNotifier.addListener(_onLitosferChanged);
  }

  @override
  void didUpdateWidget(covariant ConditionsDetailSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.atmosfer != widget.atmosfer) {
      _atmosfer = widget.atmosfer;
    }
    if (oldWidget.litosfer != widget.litosfer) {
      _litosfer = widget.litosfer;
    }
  }

  @override
  void dispose() {
    ArduinoSensorService.atmosferNotifier.removeListener(_onAtmosferChanged);
    ArduinoSensorService.litosferNotifier.removeListener(_onLitosferChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
              if (widget.type == HabitatType.atmosfer) _buildAtmosferContent(),
              if (widget.type == HabitatType.litosfer) _buildLitosferContent(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Tutup Rincian',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAtmosferContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.atmosferSky.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.air_rounded,
                      color: AppColors.atmosferSky,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Atmosfer',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          'Sirkulasi & Cuaca Mikro',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const StatusBadge(
              label: 'Sejuk',
              type: BadgeType.safe,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HumidityCapsuleGauge(
              humidityPercent: _atmosfer.humidity,
              width: 52,
              height: 120,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kelembaban ${_atmosfer.humidity}%',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tekanan ${_atmosfer.pressure} hPa',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Titik embun 24°C • Sirkulasi normal sejuk',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Metrik Udara Mikro',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        _paramGrid([
          ('Suhu Udara', '${_atmosfer.temperature}°C', 'Terasa ${_atmosfer.feelsLike}°C'),
          ('Indeks AQI', '${_atmosfer.aqi}', 'Sangat Bersih'),
          ('Kecepatan Angin', '${_atmosfer.windSpeed} km/h', 'Tenang'),
          ('Curah Hujan Saat Ini', '${_atmosfer.rainfall} mm/jam', 'Nir-Hujan'),
        ]),
      ],
    );
  }

  Widget _buildLitosferContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.litosferEmerald.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.landscape_rounded,
                      color: AppColors.litosferEmerald,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Litosfer',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          'Kelembapan Tanah & Stabilitas Lereng',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge.fromStatus(
              _litosfer.landslideRisk.toLowerCase().contains('waspada') ||
                      _litosfer.landslideRisk.toLowerCase().contains('tinggi') ||
                      _litosfer.landslideRisk.toLowerCase().contains('bahaya')
                  ? 'Waspada'
                  : 'Stabil',
            ),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              SoilRadialGauge(soilPercent: _litosfer.soilMoisture, size: 160),
              const SizedBox(height: 8),
              StatusBadge.fromStatus(
                'Risiko Longsor: ${_litosfer.landslideRisk}',
                fontSize: 12,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Sensor TDR tanah mendeteksi porositas optimal tanpa saturasi air berlebih. Risiko longsor bantaran tergolong sangat minim.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Indikator Geoteknik',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        _paramGrid([
          ('Kadar Air Tanah', '${_litosfer.soilMoisture}%', 'Stabil Normal'),
          ('Kemiringan Lereng', '${_litosfer.slopeAngle}°', 'Aman (Standar < 30°)'),
          ('Mikroseismik Lereng', _litosfer.microSeismic, 'Stabil'),
          ('Karakter Tanah', _litosfer.soilStructure, 'Daya ikat tinggi'),
        ]),
      ],
    );
  }

  Widget _paramGrid(List<(String, String, String)> items) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.$1,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                item.$2,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                item.$3,
                style: const TextStyle(
                  color: AppColors.statusSafeText,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
