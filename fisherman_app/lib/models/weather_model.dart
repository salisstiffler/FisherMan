class HourlyForecast {
  final String time;
  final String temperature;
  final String pressure;
  final String biteIndex;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.pressure,
    required this.biteIndex,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      time: json['time'] ?? '',
      temperature: json['temperature'] ?? '',
      pressure: json['pressure'] ?? '',
      biteIndex: json['biteIndex'] ?? '适宜',
    );
  }
}

class WeatherModel {
  final String temperature;
  final String pressure;
  final String humidity;
  final String wind;
  final int fishingScore;
  final String fishingStatus;
  final String advice;
  final List<HourlyForecast> hourlyForecast;

  WeatherModel({
    this.temperature = '22°C',
    this.pressure = '1013.2 hPa',
    this.humidity = '68%',
    this.wind = '东南风 2级',
    this.fishingScore = 88,
    this.fishingStatus = '适宜垂钓',
    this.advice = '气压平稳，溶氧适中，大鱼开口活跃。',
    this.hourlyForecast = const [],
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    List<HourlyForecast> forecasts = [];
    if (json['hourlyForecast'] is List) {
      forecasts = (json['hourlyForecast'] as List)
          .map((item) => HourlyForecast.fromJson(item))
          .toList();
    }

    return WeatherModel(
      temperature: json['temperature'] ?? '22°C',
      pressure: json['pressure'] ?? '1013.2 hPa',
      humidity: json['humidity'] ?? '68%',
      wind: json['wind'] ?? '东南风 2级',
      fishingScore: json['fishingScore'] ?? 85,
      fishingStatus: json['fishingStatus'] ?? '适宜垂钓',
      advice: json['advice'] ?? '气压平稳适中。',
      hourlyForecast: forecasts,
    );
  }
}
