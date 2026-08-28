import 'package:flutter/material.dart';
// ignore_for_file: deprecated_member_use
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VNumberField', () {
    testWidgets('shows required error after debounce when empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VNumberField(
              label: 'Số lượng',
              isRequired: true,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '1');
      await tester.pump();
      await tester.enterText(find.byType(TextField), '');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(VNumberValidator.defaultRequiredMessage), findsOneWidget);
    });

    testWidgets('shows max error after debounce', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VNumberField(
              label: 'Số lượng',
              max: 10,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '15');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(VNumberValidator.defaultMaxMessage(10)), findsOneWidget);
    });

    testWidgets('external errorText overrides internal error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VNumberField(
              label: 'Số lượng',
              isRequired: true,
              errorText: 'Lỗi từ parent',
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Lỗi từ parent'), findsOneWidget);
    });

    testWidgets('onChanged returns parsed int for integer mode', (tester) async {
      num? lastValue;

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: VNumberField(
              label: 'Số lượng',
              onChanged: (val) => lastValue = val,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '42');
      await tester.pump();

      expect(lastValue, 42);
    });

    testWidgets('onChanged returns parsed double for decimal mode', (tester) async {
      num? lastValue;

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: VNumberField(
              label: 'Tỷ lệ',
              allowDecimal: true,
              onChanged: (val) => lastValue = val,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '3.5');
      await tester.pump();

      expect(lastValue, 3.5);
    });

    testWidgets('formats integer input with thousand separators', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: VNumberField(
              label: 'Số lượng',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '1234567');
      await tester.pump();

      expect(find.text('1,234,567'), findsOneWidget);
    });
  });
}
