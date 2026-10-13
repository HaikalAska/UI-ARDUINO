// ============================================================================
// SERVICE INTEGRASI SENSOR ARDUINO & PYTHON (T.H.A.L.I.A)
// ============================================================================
//
// Halo Rekan Tim Arduino + Python! 👋
// File ini adalah jembatan utama antara data sensor fisik Arduino (yang dibaca
// lewat Python `pyserial`) dengan tampilan UI Beranda T.H.A.L.I.A (khususnya
// kartu **Kelembapan Tanah / Litosfer** dan **Kelembapan Udara / Atmosfer**).
//
// ----------------------------------------------------------------------------
// CONTOH KODE PYTHON SERVER (FLASK + PYSERIAL ARDUINO) - TINGGAL COPY-PASTE:
// ----------------------------------------------------------------------------
// Install dependency di terminal:
//   pip install flask flask-cors pyserial
//
// ```python
// import json, threading, serial
// from flask import Flask, jsonify
// from flask_cors import CORS
//
// app = Flask(__name__)
// CORS(app)
//
// SERIAL_PORT = 'COM3'  # Sesuaikan port Arduino (Windows: COM3/COM4, Mac/Linux: /dev/ttyUSB0)
// BAUD_RATE = 9600
//
// latest_data = {
//     "soil_moisture": 42,
//     "humidity": 70,
//     "pressure": 1012,
//     "landslide_risk": "Rendah"
// }
//
// def serial_worker():
//     global latest_data
//     try:
//         ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
//         while True:
//             line = ser.readline().decode('utf-8', errors='ignore').strip()
//             if line.startswith('{') and line.endswith('}'):
//                 latest_data.update(json.loads(line))
//             elif line.isdigit():
//                 latest_data["soil_moisture"] = int(line)
//     except Exception as e:
//         print(f"[INFO] Serial belum terhubung, memakai data terakhir: {e}")
//
// @app.route('/api/sensor', methods=['GET'])
// def get_sensor():
//     return jsonify(latest_data)
//
// if __name__ == '__main__':
//     threading.Thread(target=serial_worker, daemon=True).start()
//     app.run(host='0.0.0.0', port=5000, debug=False)
// ```
//
// ----------------------------------------------------------------------------
// CARA MENYAMBUNGKAN KE FLUTTER (PILIH SALAH SATU):
// ----------------------------------------------------------------------------
// CARA 1: OTOMATIS VIA SERVER PYTHON (FLASK / FASTAPI)
// 1. Jalankan script Python di atas hingga mengeluarkan JSON di `/api/sensor`:
//    `{"soil_moisture": 42, "humidity": 70, "pressure": 1012, "landslide_risk": "Rendah"}`
// 2. Buka `lib/config/arduino_config.dart`, masukkan IP laptop kamu di
//    `ArduinoConfig.pythonServerEndpoint`, lalu ubah
//    `ArduinoConfig.enableLiveArduinoPolling = true`.
//
// CARA 2: UPDATE LANGSUNG DARI KODE DART
// Cukup panggil fungsi statis berikut dari mana saja:
// ```dart
// // Update kelembapan tanah saja (0 - 100%):
// ArduinoSensorService.updateSoilMoisture(42);
//
// // Atau masukkan Map JSON hasil bacaan Python/Serial:
// ArduinoSensorService.applyJsonPayload({
//   'soil_moisture': 42,
//   'humidity': 70,
//   'pressure': 1012,
//   'landslide_risk': 'Rendah',
// });
// ```
// UI pada `HomeDashboardScreen` dan `ConditionsDetailSheet` mendengarkan
// `litosferNotifier` & `atmosferNotifier`, sehingga angka persentase dan grafik
// radial tanah otomatis bergerak secara real-time!
//
// Catatan: Sesuai kebutuhan saat ini, angka Suhu Utama (`28°` & `Terasa seperti 30°`)
// tetap dijaga sebagai data dummy stabil (`ArduinoConfig.keepTemperatureDummy = true`).
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../config/arduino_config.dart';
import '../models/habitat_data.dart';
import 'mock_data_service.dart';

class ArduinoSensorService {
  ArduinoSensorService._();

  /// State reaktif untuk Litosfer (Kelembapan Tanah, Risiko Longsor, Kemiringan).
  /// Didengarkan langsung oleh kartu **Tanah (Litosfer)** di `HomeDashboardScreen`
  /// dan modal `ConditionsDetailSheet`.
  static final ValueNotifier<LitosferData> litosferNotifier =
      ValueNotifier<LitosferData>(MockDataService.currentLitosfer);

  /// State reaktif untuk Atmosfer (Kelembapan Udara & Tekanan, sedangkan Suhu tetap dummy).
  /// Didengarkan langsung oleh kartu **Kelembapan (Atmosfer)** di `HomeDashboardScreen`
  /// dan modal `ConditionsDetailSheet`.
  static final ValueNotifier<AtmosferData> atmosferNotifier =
      ValueNotifier<AtmosferData>(MockDataService.currentAtmosfer);

  /// Indikator apakah aplikasi sedang menerima respons aktif dari server Python.
  static final ValueNotifier<bool> isConnectedNotifier =
      ValueNotifier<bool>(false);

  static Timer? _pollingTimer;
  static bool _isFetching = false;

  /// Getter praktis untuk nilai Litosfer saat ini.
  static LitosferData get currentLitosfer => litosferNotifier.value;

  /// Getter praktis untuk nilai Atmosfer saat ini.
  static AtmosferData get currentAtmosfer => atmosferNotifier.value;

  /// Getter praktis untuk persentase Kelembapan Tanah saat ini (0 - 100%).
  static int get soilMoisture => litosferNotifier.value.soilMoisture;

  /// Menentukan label risiko longsor otomatis berdasarkan kelembapan tanah
  /// jika server Python tidak mengirimkan field `landslide_risk` secara spesifik.
  static String evaluateLandslideRisk(int soilMoisturePercent) {
    final clamped = soilMoisturePercent.clamp(0, 100);
    if (clamped >= 75) {
      return 'Waspada (Tanah Jenuh Air)';
    } else if (clamped < 20) {
      return 'Rendah (Tanah Kering)';
    }
    return 'Rendah (Struktur Tanah Padat)';
  }

  /// Fungsi paling simpel untuk meng-update nilai **Kelembapan Tanah** (0 - 100%)
  /// dari sensor Soil Moisture Arduino.
  static void updateSoilMoisture(
    int soilMoisturePercent, {
    String? landslideRisk,
    String? soilStructure,
    double? slopeAngle,
    String? microSeismic,
  }) {
    final clampedMoisture = soilMoisturePercent.clamp(0, 100);
    final current = litosferNotifier.value;

    final resolvedRisk =
        (landslideRisk != null && landslideRisk.trim().isNotEmpty)
            ? landslideRisk.trim()
            : evaluateLandslideRisk(clampedMoisture);

    litosferNotifier.value = LitosferData(
      soilMoisture: clampedMoisture,
      landslideRisk: resolvedRisk,
      soilStructure: soilStructure ?? current.soilStructure,
      slopeAngle: slopeAngle ?? current.slopeAngle,
      microSeismic: microSeismic ?? current.microSeismic,
    );
  }

  /// Fungsi untuk meng-update **Kelembapan Udara** & **Tekanan Udara** dari sensor,
  /// sambil tetap menjaga angka Suhu utama (`28°` & `Terasa seperti 30°`) tetap dummy.
  static void updateAirHumidity(
    int humidityPercent, {
    int? pressureHpa,
  }) {
    final clampedHumidity = humidityPercent.clamp(0, 100);
    final current = atmosferNotifier.value;

    atmosferNotifier.value = AtmosferData(
      temperature: MockDataService.currentAtmosfer.temperature,
      feelsLike: MockDataService.currentAtmosfer.feelsLike,
      humidity: clampedHumidity,
      pressure: pressureHpa ?? current.pressure,
      dewPoint: current.dewPoint,
      rainfall: current.rainfall,
      weatherCondition: current.weatherCondition,
      aqi: current.aqi,
      windSpeed: current.windSpeed,
    );
  }

  /// Memproses payload JSON yang dikirim oleh script Python (Flask / FastAPI / Serial).
  /// Mendukung penamaan key snake_case (`soil_moisture`), camelCase (`soilMoisture`),
  /// maupun Bahasa Indonesia (`kelembapan_tanah`).
  static void applyJsonPayload(
    Map<String, dynamic> payload, {
    bool allowTemperatureOverride = false,
  }) {
    // 1. Baca Kelembapan Tanah (Litosfer)
    final rawSoil = payload['soil_moisture'] ??
        payload['soilMoisture'] ??
        payload['kelembapan_tanah'];
    final parsedSoil = _parseInt(rawSoil);

    final rawRisk = payload['landslide_risk'] ??
        payload['landslideRisk'] ??
        payload['risiko_longsor'];
    final rawStructure = payload['soil_structure'] ?? payload['soilStructure'];
    final rawSlope = payload['slope_angle'] ?? payload['slopeAngle'];
    final rawSeismic = payload['micro_seismic'] ?? payload['microSeismic'];

    if (parsedSoil != null ||
        rawRisk != null ||
        rawStructure != null ||
        rawSlope != null ||
        rawSeismic != null) {
      final currentLitosfer = litosferNotifier.value;
      final effectiveRisk = rawRisk != null
          ? rawRisk.toString()
          : (parsedSoil != null ? null : currentLitosfer.landslideRisk);

      updateSoilMoisture(
        parsedSoil ?? currentLitosfer.soilMoisture,
        landslideRisk: effectiveRisk,
        soilStructure: rawStructure?.toString(),
        slopeAngle: _parseDouble(rawSlope),
        microSeismic: rawSeismic?.toString(),
      );
    }

    // 2. Baca Kelembapan & Tekanan Udara (Atmosfer)
    final rawHumidity = payload['humidity'] ??
        payload['air_humidity'] ??
        payload['kelembapan_udara'];
    final rawPressure = payload['pressure'] ??
        payload['air_pressure'] ??
        payload['tekanan_udara'];

    final parsedHumidity = _parseInt(rawHumidity);
    final parsedPressure = _parseInt(rawPressure);

    final currentAtm = atmosferNotifier.value;
    final shouldKeepTempDummy =
        ArduinoConfig.keepTemperatureDummy && !allowTemperatureOverride;

    final rawTemp = payload['temperature'] ?? payload['suhu'];
    final rawFeelsLike = payload['feels_like'] ?? payload['feelsLike'];

    final resolvedTemp = shouldKeepTempDummy
        ? MockDataService.currentAtmosfer.temperature
        : (_parseDouble(rawTemp) ?? currentAtm.temperature);
    final resolvedFeelsLike = shouldKeepTempDummy
        ? MockDataService.currentAtmosfer.feelsLike
        : (_parseDouble(rawFeelsLike) ?? currentAtm.feelsLike);

    if (parsedHumidity != null ||
        parsedPressure != null ||
        (!shouldKeepTempDummy && (rawTemp != null || rawFeelsLike != null))) {
      atmosferNotifier.value = AtmosferData(
        temperature: resolvedTemp,
        feelsLike: resolvedFeelsLike,
        humidity: (parsedHumidity ?? currentAtm.humidity).clamp(0, 100),
        pressure: parsedPressure ?? currentAtm.pressure,
        dewPoint: currentAtm.dewPoint,
        rainfall: currentAtm.rainfall,
        weatherCondition: currentAtm.weatherCondition,
        aqi: currentAtm.aqi,
        windSpeed: currentAtm.windSpeed,
      );
    }
  }

  /// Mengambil data JSON terbaru dari Server Python (`GET /api/sensor`).
  /// Jika server Python belum dinyalakan atau gagal terhubung, fungsi ini
  /// otomatis menangkap error dan mengembalikan `false` tanpa membuat aplikasi crash.
  static Future<bool> fetchFromPythonServer({
    String? endpointUrl,
    Duration? timeout,
  }) async {
    final targetUrl = (endpointUrl ?? ArduinoConfig.pythonServerEndpoint).trim();
    if (targetUrl.isEmpty) {
      isConnectedNotifier.value = false;
      return false;
    }

    HttpClient? client;
    try {
      final uri = Uri.parse(targetUrl);
      final effectiveTimeout = timeout ??
          const Duration(seconds: ArduinoConfig.requestTimeoutSeconds);

      client = HttpClient()..connectionTimeout = effectiveTimeout;
      final request = await client.getUrl(uri).timeout(effectiveTimeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close().timeout(effectiveTimeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = await response
            .transform(utf8.decoder)
            .join()
            .timeout(effectiveTimeout);
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          applyJsonPayload(decoded);
          isConnectedNotifier.value = true;
          return true;
        } else if (decoded is Map) {
          applyJsonPayload(Map<String, dynamic>.from(decoded));
          isConnectedNotifier.value = true;
          return true;
        } else {
          final singleMoisture = _parseInt(decoded);
          if (singleMoisture != null) {
            updateSoilMoisture(singleMoisture);
            isConnectedNotifier.value = true;
            return true;
          }
        }
      }
    } catch (_) {
      // Fallback mulus: abaikan error jaringan jika server Python belum aktif
    } finally {
      client?.close(force: true);
    }

    isConnectedNotifier.value = false;
    return false;
  }

  /// Memulai pengambilan data otomatis secara berkala dari server Python.
  /// Hanya berjalan jika `forceStart == true` atau `ArduinoConfig.enableLiveArduinoPolling == true`.
  static void startPolling({
    String? endpointUrl,
    Duration? interval,
    bool forceStart = false,
  }) {
    stopPolling();
    if (!forceStart && !ArduinoConfig.enableLiveArduinoPolling) {
      return;
    }

    final effectiveInterval = interval ??
        const Duration(seconds: ArduinoConfig.pollingIntervalSeconds);

    Future<void> pollTick() async {
      if (_isFetching) return;
      _isFetching = true;
      try {
        await fetchFromPythonServer(endpointUrl: endpointUrl);
      } finally {
        _isFetching = false;
      }
    }

    // Ambil data pertama kali tanpa memblokir UI
    unawaited(pollTick());

    _pollingTimer = Timer.periodic(effectiveInterval, (_) {
      unawaited(pollTick());
    });
  }

  /// Menghentikan timer polling ke server Python.
  static void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Mengembalikan seluruh state sensor ke nilai awal default (berguna saat reset/testing).
  static void resetToDefault() {
    stopPolling();
    litosferNotifier.value = MockDataService.currentLitosfer;
    atmosferNotifier.value = MockDataService.currentAtmosfer;
    isConnectedNotifier.value = false;
  }

  static int? _parseInt( Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    if (value is String) {
      final cleaned = value.replaceAll('%', '').trim();
      final asInt = int.tryParse(cleaned);
      if (asInt != null) return asInt;
      final asDouble = double.tryParse(cleaned);
      if (asDouble != null) return asDouble.round();
    }
    return null;
  }

  static double? _parseDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }
}
