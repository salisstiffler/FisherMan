import 'package:fisherman_app/core/utils/fishing_navigation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('desktop shows destination and coordinates', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => FishingNavigation.open(
                  context,
                  name: '湖畔钓点',
                  address: '浙江省杭州市西湖区',
                  latitude: 30.123456,
                  longitude: 120.654321,
                ),
                child: const Text('导航'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('导航'));
      await tester.pumpAndSettle();

      expect(find.text('前往湖畔钓点'), findsOneWidget);
      expect(find.text('浙江省杭州市西湖区'), findsOneWidget);
      expect(find.text('30.123456,120.654321'), findsOneWidget);
      expect(find.text('打开路线'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
