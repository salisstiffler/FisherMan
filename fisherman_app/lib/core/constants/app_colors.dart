import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Deep Fisher Teal & River Jade
  static const Color primary = Color(0xFF087F73);
  static const Color primaryLight = Color(0xFF25B9A5);
  static const Color primaryDark = Color(0xFF075E57);

  // Secondary - Clear Water Blue
  static const Color secondary = Color(0xFF168AAD);
  static const Color secondaryLight = Color(0xFF54C6D8);

  // Trophy & Highlight - Golden Scale
  static const Color goldenFish = Color(0xFFE99B26);
  static const Color goldenLight = Color(0xFFFFCF70);

  // Status & Tags
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF97316);
  static const Color danger = Color(0xFFEF4444);

  // Neutral Colors (Dark & Light support)
  static const Color darkBackground = Color(0xFF0A1B1A);
  static const Color darkSurface = Color(0xFF112B29);
  static const Color darkSurfaceVariant = Color(0xFF20423E);

  static const Color lightBackground = Color(0xFFF1F7F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFDCEAE5);

  // Text Colors
  static const Color textPrimary = Color(0xFF142E2A);
  static const Color textSecondary = Color(0xFF5F7771);
  static const Color textMuted = Color(0xFF91A9A2);

  static const Color textLightPrimary = Color(0xFFEAF7F3);
  static const Color textLightSecondary = Color(0xFFB5D0C9);

  static const List<Color> themePalettes = [
    primary,
    Color(0xFF2878D0),
    Color(0xFF7952B3),
    Color(0xFFE17055),
    Color(0xFFB8860B),
    Color(0xFFCC4D78),
  ];

  static const List<String> themePaletteNames = [
    '湖绿',
    '海蓝',
    '暮紫',
    '珊瑚',
    '暖金',
    '莓红',
  ];
}

extension FishermanColorScheme on BuildContext {
  ColorScheme get fishermanColors => Theme.of(this).colorScheme;
  Color get fishermanBackground => Theme.of(this).scaffoldBackgroundColor;
}
