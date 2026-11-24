import 'package:flutter/material.dart';
// ignore_for_file: deprecated_member_use
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  group('VMoneyField', () {
    testWidgets('formats input with thousand separators', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: VMoneyField(
              label: 'Số tiền',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '1234567');
      await tester.pump();

      expect(find.text('1,234,567'), findsOneWidget);
    });

    testWidgets('shows required error after debounce when empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VMoneyField(
              label: 'Số tiền',
              isRequired: true,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '100');
      await tester.pump();
      await tester.enterText(find.byType(TextField), '');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(VMoneyValidator.defaultRequiredMessage), findsOneWidget);
    });

    testWidgets('shows min error after debounce', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VMoneyField(
              label: 'Số tiền',
              min: 1000,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '500');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(VMoneyValidator.defaultMinMessage(1000)), findsOneWidget);
    });

    testWidgets('external errorText overrides internal error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VMoneyField(
              label: 'Số tiền',
              isRequired: true,
              errorText: 'Lỗi từ parent',
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Lỗi từ parent'), findsOneWidget);
      expect(find.text(VMoneyValidator.defaultRequiredMessage), findsNothing);
    });

    testWidgets('onChanged returns parsed int', (tester) async {
      int? lastValue;

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: VMoneyField(
              label: 'Số tiền',
              onChanged: (val) => lastValue = val,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '1500');
      await tester.pump();

      expect(lastValue, 1500);
    });

    testWidgets('shows suffix đ by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VMoneyField(label: 'Số tiền'),
          ),
        ),
      );

      expect(find.text('đ'), findsOneWidget);
    });
  });
}
