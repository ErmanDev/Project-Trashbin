import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'navigation/app_route_observer.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Auto-rotate into landscape and keep gameplay there (no rotate prompt).
  await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const PlayToSegregateApp());
}

class PlayToSegregateApp extends StatelessWidget {
  const PlayToSegregateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Play To Segregate',
      debugShowCheckedModeBanner: false,
      navigatorObservers: <NavigatorObserver>[appRouteObserver],
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF000000),
      ),
      home: const SplashScreen(),
    );
  }
}
