import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/spots_provider.dart';
import 'providers/catches_provider.dart';
import 'providers/weather_provider.dart';
import 'views/auth/auth_screen.dart';
import 'views/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FisherManApp());
}

class FisherManApp extends StatelessWidget {
  final AuthProvider? authProvider;

  const FisherManApp({super.key, this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        if (authProvider != null)
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider!)
        else
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider<SpotsProvider>(create: (_) => SpotsProvider()),
        ChangeNotifierProvider<CatchesProvider>(create: (_) => CatchesProvider()),
        ChangeNotifierProvider<WeatherProvider>(create: (_) => WeatherProvider()),
      ],
      child: MaterialApp(
        title: '钓鱼佬',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading && auth.currentUser == null) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (auth.isAuthenticated) {
              return const MainNavigation();
            }
            return const AuthScreen();
          },
        ),
      ),
    );
  }
}
