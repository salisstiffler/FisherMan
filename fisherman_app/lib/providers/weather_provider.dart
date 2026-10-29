import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/weather_model.dart';

class WeatherProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  WeatherModel _weather = WeatherModel(
    temperature: '21°C',
    pressure: '1013.5 hPa',
    humidity: '62%',
    wind: '东风 2级 微风',
    fishingScore: 92,
    fishingStatus: '爆护指数极高',
    advice: '黄金气压区间！水溶氧量极佳，底层大鱼活跃觅食，适宜全天作钓！',
    hourlyForecast: [
      HourlyForecast(time: '06:00', temperature: '18°C', pressure: '1014.2 hPa', biteIndex: '爆护'),
      HourlyForecast(time: '09:00', temperature: '20°C', pressure: '1013.8 hPa', biteIndex: '极佳'),
      HourlyForecast(time: '12:00', temperature: '24°C', pressure: '1012.5 hPa', biteIndex: '中等'),
      HourlyForecast(time: '15:00', temperature: '23°C', pressure: '1013.0 hPa', biteIndex: '良好'),
      HourlyForecast(time: '18:00', temperature: '21°C', pressure: '1014.0 hPa', biteIndex: '爆护'),
      HourlyForecast(time: '21:00', temperature: '19°C', pressure: '1014.5 hPa', biteIndex: '极佳'),
    ],
  );

  bool _isLoading = false;

  WeatherModel get weather => _weather;
  bool get isLoading => _isLoading;

  Future<void> fetchWeather({double lat = 30.24, double lng = 120.15}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.get(
        ApiEndpoints.weather,
        queryParams: {'lat': lat, 'lng': lng},
      );

      if (res.success && res.data != null) {
        _weather = WeatherModel.fromJson(res.data);
      }
    } catch (_) {
      // Keep rich fallback model
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
