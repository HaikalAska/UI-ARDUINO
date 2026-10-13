/// Model laporan warga terverifikasi blockchain
class CitizenReport {
  final String id;
  final String category;
  final String description;
  final String locationName;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? photoPlaceholder;
  final String sha256Hash;
  final bool isVerified;
  final String statusText;

  const CitizenReport({
    required this.id,
    required this.category,
    required this.description,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.photoPlaceholder,
    required this.sha256Hash,
    required this.isVerified,
    required this.statusText,
  });
}
