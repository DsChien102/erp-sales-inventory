import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  group('VProgress', () {
    testWidgets('renders non-animated correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VProgress(
              value: 0.6,
              animated: false,
            ),
          ),
        ),
      );

      final fractionallySizedBoxFinder = find.byType(FractionallySizedBox);
      expect(fractionallySizedBoxFinder, findsOneWidget);

      final FractionallySizedBox fractionallySizedBox = tester.widget(fractionallySizedBoxFinder);
      expect(fractionallySizedBox.widthFactor, 0.6);
    });

    testWidgets('animates value changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VProgress(
              value: 0.6,
              animated: true,
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      final fractionallySizedBoxFinder = find.byType(FractionallySizedBox);
      expect(fractionallySizedBoxFinder, findsOneWidget);

      // Value starts at 0.0, animates to 0.6
      FractionallySizedBox fractionallySizedBox = tester.widget(fractionallySizedBoxFinder);
      expect(fractionallySizedBox.widthFactor, 0.0);

      await tester.pumpAndSettle();

      fractionallySizedBox = tester.widget(fractionallySizedBoxFinder);
      expect(fractionallySizedBox.widthFactor, 0.6);
    });
  });
}
