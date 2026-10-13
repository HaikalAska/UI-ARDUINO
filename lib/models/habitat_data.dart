/// Data model untuk parameter Atmosfer, Hidrosfer, dan Litosfer (T.H.A.L.I.A)
class AtmosferData {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final int pressure;
  final double dewPoint;
  final double rainfall;
  final String weatherCondition;
  final int aqi;
  final double windSpeed;

  const AtmosferData({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.pressure,
    required this.dewPoint,
    required this.rainfall,
    required this.weatherCondition,
    required this.aqi,
    required this.windSpeed,
  });
}

class HidrosferData {
  final double ph;
  final String status;
  final String subInfo;
  final double dissolvedOxygen;
  final double turbidity;
  final double waterTemp;

  const HidrosferData({
    required this.ph,
    required this.status,
    required this.subInfo,
    required this.dissolvedOxygen,
    required this.turbidity,
    required this.waterTemp,
  });
}

class LitosferData {
  final int soilMoisture;
  final String landslideRisk;
  final String soilStructure;
  final double slopeAngle;
  final String microSeismic;

  const LitosferData({
    required this.soilMoisture,
    required this.landslideRisk,
    required this.soilStructure,
    required this.slopeAngle,
    required this.microSeismic,
  });
}

class BlockchainProof {
  final String network;
  final String contractAddress;
  final String transactionHash;
  final int blockNumber;
  final String timestamp;
  final String status;

  const BlockchainProof({
    required this.network,
    required this.contractAddress,
    required this.transactionHash,
    required this.blockNumber,
    required this.timestamp,
    required this.status,
  });
}
