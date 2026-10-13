import 'dart:convert';
import 'package:crypto/crypto.dart';

class BlockchainService {
  BlockchainService._();

  static const String sepoliaContractAddress =
      '0x7B9C3481e18d99d3B9B749aCfe1102A67651a14D';

  /// Menghitung SHA-256 hash dari data teks/laporan
  static String calculateSha256(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return '0x${digest.toString()}';
  }

  /// Menghasilkan hash bukti integritas data stasiun pemantau
  static String generateTelemetryHash({
    required double temperature,
    required double ph,
    required int soilMoisture,
    required DateTime timestamp,
  }) {
    final payload =
        'THALIA:$temperature:$ph:$soilMoisture:${timestamp.toIso8601String()}:$sepoliaContractAddress';
    return calculateSha256(payload);
  }

  /// Menghasilkan hash verifikasi laporan warga
  static String generateReportHash({
    required String category,
    required String description,
    required double latitude,
    required double longitude,
    required DateTime timestamp,
  }) {
    final payload =
        'REPORT:$category:$description:$latitude:$longitude:${timestamp.millisecondsSinceEpoch}';
    return calculateSha256(payload);
  }
}
