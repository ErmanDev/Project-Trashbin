import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/main_menu_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock the app to landscape orientation.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
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
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
    );
  }
}
