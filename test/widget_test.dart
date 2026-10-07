import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habit_tracker/screens/home_screen.dart';

String _today() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

Future<List<dynamic>> _savedHabits() async {
  final prefs = await SharedPreferences.getInstance();
  return jsonDecode(prefs.getString('habits')!) as List<dynamic>;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'habits': jsonEncode([
        {'id': '1', 'name': 'Drink Water', 'completedDates': <String>[]},
      ]),
    });
  });

  // Regression: on a fresh open, today's tick box used to be treated as a
  // "future" day (the selected date carried the current time of day), so it
  // was disabled until the user tapped a date in the strip.
  testWidgets('today can be ticked straight after opening the app',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.textContaining("can't log future days"), findsNothing);

    await tester.tap(find.byIcon(Icons.check_box_outline_blank));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_box), findsOneWidget);
    final saved = await _savedHabits();
    expect(saved.first['completedDates'], contains(_today()));
  });

  testWidgets('tapping again un-ticks today', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check_box_outline_blank));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check_box));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    final saved = await _savedHabits();
    expect(saved.first['completedDates'], isEmpty);
  });
}
