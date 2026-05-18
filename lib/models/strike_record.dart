import 'weather_conditions.dart';

class StrikeRecord {
  final DateTime timestamp;
  final double delaySeconds;
  final double estimatedDistanceKm;
  final WeatherConditions weatherConditions;

  const StrikeRecord({
    required this.timestamp,
    required this.delaySeconds,
    required this.estimatedDistanceKm,
    required this.weatherConditions,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'delaySeconds': delaySeconds,
      'estimatedDistanceKm': estimatedDistanceKm,
      'weatherConditions': weatherConditions.toJson(),
    };
  }

  factory StrikeRecord.fromJson(Map<String, dynamic> json) {
    return StrikeRecord(
      timestamp: DateTime.parse(json['timestamp'] as String),
      delaySeconds: json['delaySeconds'] as double,
      estimatedDistanceKm: json['estimatedDistanceKm'] as double,
      weatherConditions: WeatherConditions.fromJson(
          json['weatherConditions'] as Map<String, dynamic>),
    );
  }
}
