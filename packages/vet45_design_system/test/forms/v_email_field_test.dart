import 'package:flutter/material.dart';
// ignore_for_file: deprecated_member_use
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VEmailField', () {
    testWidgets('shows internal error after debounce for invalid email', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VEmailField(
              key: Key('optional-email'),
              label: 'Email',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'bad-email');
      await tester.pump();
      expect(find.text(VEmailValidator.defaultInvalidEmailMessage), findsNothing);

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(VEmailValidator.defaultInvalidEmailMessage), findsOneWidget);
    });

    testWidgets('shows min length error after debounce', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VEmailField(
              label: 'Email',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text(VEmailValidator.defaultMinLengthEmailMessage(VEmailValidator.defaultMinLength)),
        findsOneWidget,
      );
    });

    testWidgets('shows required error after debounce when empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VEmailField(
              label: 'Email',
              isRequired: true,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump();
      await tester.enterText(find.byType(TextField), '');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(VEmailValidator.defaultRequiredEmailMessage), findsOneWidget);
    });

    testWidgets('external errorText overrides internal error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VEmailField(
              label: 'Email',
              errorText: 'Lỗi từ parent',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'invalid');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Lỗi từ parent'), findsOneWidget);
      expect(find.text(VEmailValidator.defaultInvalidEmailMessage), findsNothing);
    });

    testWidgets('onChanged is called on every keystroke', (tester) async {
      final values = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: VEmailField(
              label: 'Email',
              onChanged: values.add,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'ab');
      await tester.pump();

      expect(values, ['a', 'ab']);
    });

    testWidgets('clears internal error when optional field becomes empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VEmailField(
              label: 'Email',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'invalid');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(VEmailValidator.defaultInvalidEmailMessage), findsOneWidget);

      await tester.enterText(find.byType(TextField), '');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(VEmailValidator.defaultInvalidEmailMessage), findsNothing);
    });
  });
}
