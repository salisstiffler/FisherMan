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

class DailyForecast {
  final String day;
  final String tempRange;
  final String pressureRange;
  final int fishingScore;
  final String status;

  DailyForecast({
    required this.day,
    required this.tempRange,
    required this.pressureRange,
    required this.fishingScore,
    required this.status,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      day: json['day'] ?? '',
      tempRange: json['tempRange'] ?? '',
      pressureRange: json['pressureRange'] ?? '',
      fishingScore: json['fishingScore'] ?? 80,
      status: json['status'] ?? '适宜垂钓',
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
  final String source;
  final List<HourlyForecast> hourlyForecast;
  final List<DailyForecast> dailyForecast;

  WeatherModel({
    this.temperature = '--',
    this.pressure = '--',
    this.humidity = '--',
    this.wind = '--',
    this.fishingScore = 0,
    this.fishingStatus = '天气数据加载中',
    this.advice = '',
    this.source = '',
    this.hourlyForecast = const [],
    this.dailyForecast = const [],
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    List<HourlyForecast> forecasts = [];
    if (json['hourlyForecast'] is List) {
      forecasts = (json['hourlyForecast'] as List)
          .map((item) => HourlyForecast.fromJson(item))
          .toList();
    }

    List<DailyForecast> dailies = [];
    if (json['dailyForecast'] is List) {
      dailies = (json['dailyForecast'] as List)
          .map((item) => DailyForecast.fromJson(item))
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
      source: json['source'] ?? '',
      hourlyForecast: forecasts,
      dailyForecast: dailies,
    );
  }
}
