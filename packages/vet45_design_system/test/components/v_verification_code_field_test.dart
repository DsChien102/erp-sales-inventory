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

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(6));

      for (var i = 0; i < 6; i++) {
        await tester.enterText(fields.at(i), '${i + 1}');
        await tester.pump();
      }

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

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(8));

      const chars = 'k7p29xqm';
      for (var i = 0; i < chars.length; i++) {
        await tester.enterText(fields.at(i), chars[i]);
        await tester.pump();
      }

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

      await tester.enterText(find.byType(TextField).first, '@');
      await tester.pump();
      final firstField = tester.widget<TextField>(find.byType(TextField).first);
      expect(firstField.controller?.text ?? '', isEmpty);
      expect(latest == 'unset' || latest.isEmpty, isTrue);
    });
  });
}
