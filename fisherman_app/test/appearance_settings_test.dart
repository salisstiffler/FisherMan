import 'package:fisherman_app/core/constants/app_colors.dart';
import 'package:fisherman_app/core/theme/app_theme.dart';
import 'package:fisherman_app/providers/appearance_provider.dart';
import 'package:fisherman_app/views/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('theme mode and accent color update and persist', (tester) async {
    final appearance = AppearanceProvider();
    await appearance.init();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appearance,
        child: Consumer<AppearanceProvider>(
          builder: (context, currentAppearance, _) => MaterialApp(
            theme: AppTheme.lightTheme(
              accentColor: currentAppearance.accentColor,
            ),
            darkTheme: AppTheme.darkTheme(
              accentColor: currentAppearance.accentColor,
            ),
            themeMode: currentAppearance.themeMode,
            home: const SettingsScreen(),
          ),
        ),
      ),
    );

    expect(find.text('设置'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(appearance.themeMode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.text('设置'))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.byKey(const ValueKey('theme-color-海蓝')));
    await tester.pumpAndSettle();
    expect(appearance.accentColor, AppColors.themePalettes[1]);

    final restored = AppearanceProvider();
    await restored.init();
    expect(restored.themeMode, ThemeMode.dark);
    expect(restored.accentColor, AppColors.themePalettes[1]);
  });
}
