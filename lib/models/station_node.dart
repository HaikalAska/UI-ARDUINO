/// Model stasiun pemantau wilayah sekitar (Radius 10 km)
class StationNode {
  final String id;
  final String name;
  final double distanceKm;
  final String weatherCondition;
  final double temperature;
  final double ph;
  final String phStatus;
  final String overallStatus; // "Aman", "Waspada", "Bahaya"
  final double latitude;
  final double longitude;
  final int solarLevel;

  const StationNode({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.weatherCondition,
    required this.temperature,
    required this.ph,
    required this.phStatus,
    required this.overallStatus,
    required this.latitude,
    required this.longitude,
    this.solarLevel = 94,
  });
}
