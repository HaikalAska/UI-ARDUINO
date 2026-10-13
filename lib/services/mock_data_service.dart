import '../config/arduino_config.dart';
import '../config/map_config.dart';
import '../models/habitat_data.dart';
import '../models/station_node.dart';
import '../models/citizen_report.dart';
import '../models/historical_log.dart';
import 'blockchain_service.dart';

class MockDataService {
  MockDataService._();

  static const AtmosferData currentAtmosfer = AtmosferData(
    temperature: 28.0,
    feelsLike: 30.0,
    humidity: ArduinoConfig.defaultAirHumidity,
    pressure: ArduinoConfig.defaultAirPressure,
    dewPoint: 24.0,
    rainfall: 0.0,
    weatherCondition: 'Cerah Berawan',
    aqi: 32,
    windSpeed: 8.5,
  );

  static const HidrosferData currentHidrosfer = HidrosferData(
    ph: 7.2,
    status: 'Kualitas Baik • Air Bersih Alami',
    subInfo:
        'Aman untuk ekosistem dan aktivitas rumah tangga sekitar aliran air. (Bebas metrik ketinggian/debit air).',
    dissolvedOxygen: 6.8,
    turbidity: 3.8,
    waterTemp: 26.5,
  );

  static const LitosferData currentLitosfer = LitosferData(
    soilMoisture: ArduinoConfig.defaultSoilMoisture,
    landslideRisk: 'Rendah (Struktur Tanah Padat)',
    soilStructure: 'Tanah Aluvial & Lempung Pasir Padat',
    slopeAngle: 12.0,
    microSeismic: 'Normal (0.01g)',
  );

  static final BlockchainProof currentBlockchainProof = BlockchainProof(
    network: 'Ethereum Sepolia Testnet',
    contractAddress: BlockchainService.sepoliaContractAddress,
    transactionHash:
        '0x7b4a8e9f2a41d9ce2a10b4578b9c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8',
    blockNumber: 6428910,
    timestamp: '2026-09-18 07:15:32 UTC',
    status: 'Data Terkunci di Smart Contract Sepolia • Hash SHA-256 Valid',
  );

  /// Daftar wilayah sekitar (Radius 10 km) dengan koordinat nyata DKI Jakarta
  static const List<StationNode> surroundingStations = [
    StationNode(
      id: 'node-jaktim',
      name: 'Jakarta Timur',
      distanceKm: 1.8,
      weatherCondition: 'Cerah',
      temperature: 29.0,
      ph: 7.1,
      phStatus: 'Baik',
      overallStatus: 'Aman',
      latitude: MapConfig.jaktimLat, // -6.2320 (Kampung Melayu / Cawang)
      longitude: MapConfig.jaktimLng, // 106.8670
      solarLevel: 96,
    ),
    StationNode(
      id: 'node-jaksel',
      name: 'Jakarta Selatan',
      distanceKm: 3.4,
      weatherCondition: 'Berawan',
      temperature: 28.0,
      ph: 7.0,
      phStatus: 'Baik',
      overallStatus: 'Aman',
      latitude: MapConfig.jakselLat, // -6.2150 (Tebet / Manggarai)
      longitude: MapConfig.jakselLng, // 106.8480
      solarLevel: 91,
    ),
    StationNode(
      id: 'node-jakpus',
      name: 'Jakarta Pusat',
      distanceKm: 4.2,
      weatherCondition: 'Cerah',
      temperature: 30.0,
      ph: 7.3,
      phStatus: 'Baik',
      overallStatus: 'Aman',
      latitude: MapConfig.jakpusLat, // -6.1950 (Menteng / Tanah Abang)
      longitude: MapConfig.jakpusLng, // 106.8320
      solarLevel: 98,
    ),
    StationNode(
      id: 'node-jakbar',
      name: 'Jakarta Barat',
      distanceKm: 7.1,
      weatherCondition: 'Mendung',
      temperature: 28.0,
      ph: 6.9,
      phStatus: 'Baik',
      overallStatus: 'Aman',
      latitude: MapConfig.jakbarLat, // -6.1780 (Tomang / Grogol)
      longitude: MapConfig.jakbarLng, // 106.7950
      solarLevel: 88,
    ),
    StationNode(
      id: 'node-jakut',
      name: 'Jakarta Utara',
      distanceKm: 10.8,
      weatherCondition: 'Angin',
      temperature: 29.0,
      ph: 6.4,
      phStatus: 'Waspada',
      overallStatus: 'Waspada',
      latitude: MapConfig.jakutLat, // -6.1280 (Ancol / Penjaringan)
      longitude: MapConfig.jakutLng, // 106.8350
      solarLevel: 92,
    ),
  ];

  /// Daftar riwayat kalender faktual (bukan ramalan cuaca)
  static final List<HistoricalLog> historicalLogs = [
    HistoricalLog(
      date: DateTime(2026, 9, 17),
      dayName: 'Kamis',
      formattedDate: '17 September 2026',
      weatherType: 'rain',
      weatherLabel: 'Hujan Sedang (18 mm)',
      rainfallMm: 18.0,
      avgTemp: 27.2,
      avgPh: 7.0,
      soilMoisture: 45,
      summaryText:
          'Kemarin (Kamis): Hujan sedang tercatat 18mm, kualitas pH air tetap stabil di 7.0, tanah basah aman.',
      isYesterday: true,
    ),
    HistoricalLog(
      date: DateTime(2026, 9, 16),
      dayName: 'Rabu',
      formattedDate: '16 September 2026',
      weatherType: 'cloudy',
      weatherLabel: 'Berawan Tipis',
      rainfallMm: 2.0,
      avgTemp: 28.6,
      avgPh: 7.1,
      soilMoisture: 39,
      summaryText:
          'Rabu: Kondisi berawan stabil, gerimis lokal singkat 2mm, pH air 7.1 dalam batas aman ekosistem.',
    ),
    HistoricalLog(
      date: DateTime(2026, 9, 15),
      dayName: 'Selasa',
      formattedDate: '15 September 2026',
      weatherType: 'sunny',
      weatherLabel: 'Cerah Berawan',
      rainfallMm: 0.0,
      avgTemp: 29.4,
      avgPh: 7.2,
      soilMoisture: 36,
      summaryText:
          'Selasa: Paparan sinar matahari optimal, tanpa presipitasi hujan, kelembaban tanah 36% padat normal.',
    ),
    HistoricalLog(
      date: DateTime(2026, 9, 14),
      dayName: 'Senin',
      formattedDate: '14 September 2026',
      weatherType: 'sunny',
      weatherLabel: 'Cerah',
      rainfallMm: 0.0,
      avgTemp: 30.1,
      avgPh: 7.3,
      soilMoisture: 34,
      summaryText:
          'Senin: Suhu siang mencapai 30.1°C, pH air sedikit meningkat ke 7.3 (kategori bersih murni).',
    ),
    HistoricalLog(
      date: DateTime(2026, 9, 13),
      dayName: 'Minggu',
      formattedDate: '13 September 2026',
      weatherType: 'rain',
      weatherLabel: 'Hujan Lebat (32 mm)',
      rainfallMm: 32.0,
      avgTemp: 26.5,
      avgPh: 6.9,
      soilMoisture: 48,
      summaryText:
          'Minggu: Hujan lebat monsun terakumulasi 32mm, lereng bantaran tetap kokoh tanpa indikasi retakan.',
    ),
    HistoricalLog(
      date: DateTime(2026, 9, 12),
      dayName: 'Sabtu',
      formattedDate: '12 September 2026',
      weatherType: 'cloudy',
      weatherLabel: 'Mendung',
      rainfallMm: 6.5,
      avgTemp: 27.8,
      avgPh: 7.0,
      soilMoisture: 41,
      summaryText:
          'Sabtu: Hujan rintik sore hari, kualitas air sungai Ciliwung terpantau jernih dengan pH 7.0 stabil.',
    ),
    HistoricalLog(
      date: DateTime(2026, 9, 11),
      dayName: 'Jumat',
      formattedDate: '11 September 2026',
      weatherType: 'sunny',
      weatherLabel: 'Cerah',
      rainfallMm: 0.0,
      avgTemp: 29.0,
      avgPh: 7.2,
      soilMoisture: 35,
      summaryText:
          'Jumat pekan lalu: Parameter tri-habitat optimal, panel surya stasiun mengisi daya 100%.',
    ),
  ];

  /// Laporan warga awal yang telah tercatat on-chain
  static final List<CitizenReport> initialCitizenReports = [
    CitizenReport(
      id: 'rep-001',
      category: 'Air Berbau / Keruh',
      description:
          'Air bantaran dekat jembatan sedikit keruh pasca hujan lebat minggu lalu, namun bau tidak tercium.',
      locationName: 'Bantaran Ciliwung Km 4.2',
      latitude: -6.2040,
      longitude: 106.8640,
      timestamp: DateTime(2026, 9, 17, 14, 20),
      photoPlaceholder: 'camera_geotag_ciliwung_km42.jpg',
      sha256Hash:
          '0xa7c2e819b5d40f2834c718a291f048d6174a91b2c83d9e4a7b6c5d1e2f3a4b5c',
      isVerified: true,
      statusText: 'Terverifikasi',
    ),
    CitizenReport(
      id: 'rep-002',
      category: 'Pohon Tumbang',
      description:
          'Dahan pohon trembesi patah di tepi jalan inspeksi, relawan sudah menepikan ke pinggir.',
      locationName: 'Jl. Inspeksi Ciliwung Timur',
      latitude: -6.2480,
      longitude: 106.8420,
      timestamp: DateTime(2026, 9, 18, 6, 45),
      photoPlaceholder: 'camera_geotag_pohon_tumbang.jpg',
      sha256Hash:
          '0x9f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a',
      isVerified: true,
      statusText: 'Terverifikasi',
    ),
    CitizenReport(
      id: 'rep-003',
      category: 'Retakan Lereng',
      description:
          'Ditemukan retakan rambut mikro sepanjang 1 meter di lereng rumput dekat pos 3.',
      locationName: 'Pos Pantau 3 Ciliwung',
      latitude: -6.1620,
      longitude: 106.8620,
      timestamp: DateTime(2026, 9, 18, 7, 10),
      photoPlaceholder: 'camera_geotag_retakan_lereng.jpg',
      sha256Hash:
          '0x3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e',
      isVerified: false,
      statusText: 'Menunggu Verifikasi Tim Relawan',
    ),
  ];

  /// Shared active citizen reports in-memory list
  static final List<CitizenReport> citizenReports =
      List<CitizenReport>.from(initialCitizenReports);

  static void addCitizenReport(CitizenReport report) {
    citizenReports.insert(0, report);
  }

  static void resetCitizenReports() {
    citizenReports.clear();
    citizenReports.addAll(initialCitizenReports);
  }
}
