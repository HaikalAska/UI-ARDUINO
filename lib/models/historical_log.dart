/// Model pencatatan sejarah riil / riwayat faktual (Bukan ramalan cuaca)
class HistoricalLog {
  final DateTime date;
  final String dayName;
  final String formattedDate;
  final String weatherType; // 'rain', 'cloudy', 'sunny'
  final String weatherLabel;
  final double rainfallMm;
  final double avgTemp;
  final double avgPh;
  final int soilMoisture;
  final String summaryText;
  final bool isYesterday;

  const HistoricalLog({
    required this.date,
    required this.dayName,
    required this.formattedDate,
    required this.weatherType,
    required this.weatherLabel,
    required this.rainfallMm,
    required this.avgTemp,
    required this.avgPh,
    required this.soilMoisture,
    required this.summaryText,
    this.isYesterday = false,
  });
}
