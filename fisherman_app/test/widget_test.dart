import 'package:flutter_test/flutter_test.dart';
import 'package:fisherman_app/main.dart';
import 'package:fisherman_app/providers/auth_provider.dart';
import 'package:fisherman_app/views/auth/auth_screen.dart';

void main() {
  testWidgets('FisherMan app smoke and launch test', (WidgetTester tester) async {
    final authProvider = AuthProvider();

    // Pump with initialized provider
    await tester.pumpWidget(FisherManApp(authProvider: authProvider));
    await tester.pump();

    // Verify that the branding and auth screen render properly
    expect(find.byType(FisherManApp), findsOneWidget);
    expect(find.text('钓鱼佬'), findsWidgets);
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('免注册一键体验 (游客模式)'), findsOneWidget);
  });
}
