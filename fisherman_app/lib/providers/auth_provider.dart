import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isGuest = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuest => _isGuest;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.init();
      final prefs = await SharedPreferences.getInstance();
      final cachedUserJson = prefs.getString('cached_user');
      if (cachedUserJson != null) {
        _currentUser = UserModel.fromJson(jsonDecode(cachedUserJson));
      }

      if (_api.authToken != null) {
        // Refresh profile from server
        final res = await _api.get(ApiEndpoints.me);
        if (res.success && res.data != null) {
          _currentUser = UserModel.fromJson(res.data);
          await _saveCachedUser(_currentUser!);
        }
      }
    } catch (e) {
      debugPrint('Auth init failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.post(
        ApiEndpoints.login,
        body: {'username': username, 'password': password},
      );

      if (res.success && res.data != null) {
        final token = res.data['token'];
        final refreshToken = res.data['refreshToken'];
        final user = UserModel.fromJson(res.data['user']);
        
        _api.setToken(token, refreshToken);
        _currentUser = user;
        _isGuest = false;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        if (refreshToken != null) {
          await prefs.setString('refresh_token', refreshToken);
        }
        await _saveCachedUser(user);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = '登录出错: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String password, String nickname) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.post(
        ApiEndpoints.register,
        body: {
          'username': username,
          'password': password,
          'nickname': nickname,
        },
      );

      if (res.success && res.data != null) {
        final token = res.data['token'];
        final refreshToken = res.data['refreshToken'];
        final user = UserModel.fromJson(res.data['user']);
        
        _api.setToken(token, refreshToken);
        _currentUser = user;
        _isGuest = false;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        if (refreshToken != null) {
          await prefs.setString('refresh_token', refreshToken);
        }
        await _saveCachedUser(user);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = '注册出错: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void enterGuestMode() {
    _isGuest = true;
    _currentUser = UserModel(
      id: 9999,
      username: 'guest_angler',
      nickname: '游客钓友',
      avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      bio: '以游客身份探索各路水域与渔获战报',
      fishingYears: 1,
      targetFish: '鲫鱼、鲤鱼',
      stats: UserStats(
        spotsCreated: 0,
        catchesCount: 0,
        totalWeightKg: 0,
        maxWeightKg: 0,
        badges: [UserBadge(id: 'guest', name: '探索客', icon: '🚣')],
      ),
    );
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    _isGuest = false;
    _api.setToken(null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('cached_user');

    notifyListeners();
  }

  Future<bool> updateProfile({
    String? nickname,
    String? bio,
    int? fishingYears,
    String? targetFish,
  }) async {
    if (_currentUser == null) return false;
    if (_isGuest) {
      _currentUser = _currentUser!.copyWith(
        nickname: nickname,
        bio: bio,
        fishingYears: fishingYears,
        targetFish: targetFish,
      );
      notifyListeners();
      return true;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.post(
        ApiEndpoints.profile,
        body: {
          'nickname': nickname ?? _currentUser!.nickname,
          'bio': bio ?? _currentUser!.bio,
          'fishing_years': fishingYears ?? _currentUser!.fishingYears,
          'target_fish': targetFish ?? _currentUser!.targetFish,
        },
      );

      if (res.success && res.data != null) {
        _currentUser = UserModel.fromJson(res.data);
        await _saveCachedUser(_currentUser!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Profile update failed: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> _saveCachedUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user', jsonEncode(user.toJson()));
  }
}
