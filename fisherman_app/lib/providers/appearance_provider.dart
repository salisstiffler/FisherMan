import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_colors.dart';

class AppearanceProvider extends ChangeNotifier {
  static const _themeModeKey = 'appearance_theme_mode';
  static const _accentColorKey = 'appearance_accent_color';

  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = AppColors.primary;

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;

  Future<void> init() async {
    final preferences = await SharedPreferences.getInstance();
    final savedMode = preferences.getString(_themeModeKey);
    _themeMode = switch (savedMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final savedColor = preferences.getInt(_accentColorKey);
    if (savedColor != null &&
        AppColors.themePalettes.any(
          (color) => color.toARGB32() == savedColor,
        )) {
      _accentColor = Color(savedColor);
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_themeModeKey, mode.name);
    if (!saved) throw StateError('无法保存主题模式');
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    if (!AppColors.themePalettes.any(
      (palette) => palette.toARGB32() == color.toARGB32(),
    )) {
      throw ArgumentError.value(color, 'color', '不支持的主题颜色');
    }
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setInt(_accentColorKey, color.toARGB32());
    if (!saved) throw StateError('无法保存主题颜色');
    _accentColor = color;
    notifyListeners();
  }
}
