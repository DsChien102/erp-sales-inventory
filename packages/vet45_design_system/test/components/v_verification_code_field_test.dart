import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );
  }

  group('VVerificationCodeField', () {
    testWidgets('numeric mode completes 6 digits', (tester) async {
      String? completed;
      await tester.pumpWidget(
        wrap(
          VVerificationCodeField(
            onCompleted: (code) => completed = code,
          ),
        ),
      );

      // Single hidden TextField drives all cells.
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();

      expect(completed, '123456');
    });

    testWidgets('alphanumeric mode uppercases and completes 8 chars', (
      tester,
    ) async {
      String? completed;
      String? latest;
      await tester.pumpWidget(
        wrap(
          VVerificationCodeField(
            length: 8,
            charset: VVerificationCodeCharset.alphanumeric,
            onChanged: (code) => latest = code,
            onCompleted: (code) => completed = code,
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'k7p29xqm');
      await tester.pump();

      expect(latest, 'K7P29XQM');
      expect(completed, 'K7P29XQM');
    });

    testWidgets('alphanumeric rejects symbols', (tester) async {
      var latest = 'unset';
      await tester.pumpWidget(
        wrap(
          VVerificationCodeField(
            length: 8,
            charset: VVerificationCodeCharset.alphanumeric,
            onChanged: (code) => latest = code,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '@');
      await tester.pump();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text ?? '', isEmpty);
      expect(latest == 'unset' || latest.isEmpty, isTrue);
    });

    testWidgets('legacy flat label and helper still render', (tester) async {
      await tester.pumpWidget(
        wrap(
          // ignore: deprecated_member_use
          const VVerificationCodeField(
            // ignore: deprecated_member_use
            label: 'OTP',
            // ignore: deprecated_member_use
            helperText: 'From SMS',
            // ignore: deprecated_member_use
            isRequired: true,
          ),
        ),
      );
      expect(find.text('OTP'), findsOneWidget);
      expect(find.text('From SMS'), findsOneWidget);
      expect(find.text(' *'), findsOneWidget);
    });
  });
}
