enum HumidityLevel { low, medium, high }
enum WindLevel { calm, breezy, windy }

class WeatherConditions {
  final double temperatureCelsius;
  final HumidityLevel humidity;
  final WindLevel wind;

  const WeatherConditions({
    this.temperatureCelsius = 25.0,
    this.humidity = HumidityLevel.medium,
    this.wind = WindLevel.calm,
  });

  WeatherConditions copyWith({
    double? temperatureCelsius,
    HumidityLevel? humidity,
    WindLevel? wind,
  }) {
    return WeatherConditions(
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      humidity: humidity ?? this.humidity,
      wind: wind ?? this.wind,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperatureCelsius': temperatureCelsius,
      'humidity': humidity.index,
      'wind': wind.index,
    };
  }

  factory WeatherConditions.fromJson(Map<String, dynamic> json) {
    return WeatherConditions(
      temperatureCelsius: json['temperatureCelsius'] as double? ?? 25.0,
      humidity: HumidityLevel.values[json['humidity'] as int? ?? 1],
      wind: WindLevel.values[json['wind'] as int? ?? 0],
    );
  }
}
