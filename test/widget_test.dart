// This is a basic Flutter widget test.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:play_to_segregate/main.dart';
import 'package:play_to_segregate/screens/splash_screen.dart';

void main() {
  testWidgets('Splash then main menu renders title and buttons',
      (WidgetTester tester) async {
    final TestFlutterView view = tester.view;
    view.physicalSize = const Size(800, 400);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await tester.pumpWidget(const PlayToSegregateApp());
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Rotate your device'), findsNothing);

    // Advance past Unity-style splash fade-in / hold / fade-out.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Play To Segregate'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Exit'), findsOneWidget);
  });
}
