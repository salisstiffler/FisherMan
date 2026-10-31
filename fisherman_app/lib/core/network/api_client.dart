import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'api_endpoints.dart';

class ApiResponse<T> {
  final bool success;
  final int code;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.code,
    required this.message,
    this.data,
  });
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String _baseUrl = AppConstants.defaultApiUrl;
  String? _authToken;
  String? _refreshToken;

  String get baseUrl => _baseUrl;
  String? get authToken => _authToken;
  String? get refreshToken => _refreshToken;

  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  void setToken(String? token, [String? refreshToken]) {
    _authToken = token;
    if (refreshToken != null) {
      _refreshToken = refreshToken;
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _refreshToken = prefs.getString('refresh_token');
    final savedUrl = prefs.getString('api_base_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl;
    }
  }

  Map<String, String> _buildHeaders([Map<String, String>? extra]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  Future<ApiResponse<dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      Uri uri = Uri.parse('$_baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        final stringParams = queryParams.map(
          (k, v) => MapEntry(k, v.toString()),
        );
        uri = uri.replace(queryParameters: stringParams);
      }

      var response = await http
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 401 && _refreshToken != null) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          response = await http
              .get(uri, headers: _buildHeaders())
              .timeout(const Duration(seconds: 8));
        }
      }

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, code: 500, message: '网络连接异常: $e');
    }
  }

  Future<ApiResponse<dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http
          .post(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 8));

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, code: 500, message: '网络连接异常: $e');
    }
  }

  Future<ApiResponse<dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http
          .put(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 8));

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, code: 500, message: '网络连接异常: $e');
    }
  }

  Future<ApiResponse<dynamic>> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http
          .delete(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 8));

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, code: 500, message: '网络连接异常: $e');
    }
  }

  Future<ApiResponse<dynamic>> uploadImage(
    Uint8List bytes,
    String filename,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl${ApiEndpoints.upload}'),
      );
      if (_authToken != null && _authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      request.headers['Accept'] = 'application/json';
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, code: 500, message: '图片上传失败: $e');
    }
  }

  Future<bool> _tryRefreshToken() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) return false;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl${ApiEndpoints.refresh}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        if (body['data'] != null) {
          final newToken = body['data']['token'];
          final newRefresh = body['data']['refreshToken'];
          _authToken = newToken;
          if (newRefresh != null) _refreshToken = newRefresh;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', newToken);
          if (newRefresh != null) {
            await prefs.setString('refresh_token', newRefresh);
          }
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  ApiResponse<dynamic> _handleResponse(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: true,
          code: body['code'] ?? response.statusCode,
          message: body['message'] ?? 'OK',
          data: body['data'],
        );
      } else {
        return ApiResponse(
          success: false,
          code: body['code'] ?? response.statusCode,
          message: body['message'] ?? '请求失败 (${response.statusCode})',
          data: body['data'],
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        code: response.statusCode,
        message: '解析响应异常: $e',
      );
    }
  }
}
