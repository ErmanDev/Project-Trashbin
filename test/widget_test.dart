// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';

import 'package:play_to_segregate/main.dart';

void main() {
  testWidgets('Main menu renders title and buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PlayToSegregateApp());

    expect(find.text('Play To Segregate'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Exit'), findsOneWidget);
  });
}
