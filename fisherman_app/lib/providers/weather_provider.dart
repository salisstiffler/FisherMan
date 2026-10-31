import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/weather_model.dart';

class WeatherProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  WeatherModel _weather = WeatherModel();

  bool _isLoading = false;
  String? _errorMessage;

  WeatherModel get weather => _weather;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchWeather({double lat = 30.24, double lng = 120.15}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get(
        ApiEndpoints.weather,
        queryParams: {'lat': lat, 'lng': lng},
      );

      if (res.success && res.data != null) {
        _weather = WeatherModel.fromJson(res.data);
      } else {
        _errorMessage = res.message;
      }
    } catch (error) {
      _errorMessage = '天气数据获取失败: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
