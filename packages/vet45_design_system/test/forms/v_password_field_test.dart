import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VPasswordField', () {
    testWidgets('shows min length error after debounce', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VPasswordField(
              label: 'Mật khẩu',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'short');
      await tester.pump();
      expect(
        find.text(
          VPasswordValidator.defaultMinLengthPasswordMessage(
            VPasswordValidator.defaultMinLength,
          ),
        ),
        findsNothing,
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text(
          VPasswordValidator.defaultMinLengthPasswordMessage(
            VPasswordValidator.defaultMinLength,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows required error after debounce when empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VPasswordField(
              label: 'Mật khẩu',
              isRequired: true,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump();
      await tester.enterText(find.byType(TextField), '');
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text(VPasswordValidator.defaultRequiredPasswordMessage),
        findsOneWidget,
      );
    });

    testWidgets('external errorText overrides internal error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VPasswordField(
              label: 'Mật khẩu',
              errorText: 'Lỗi từ parent',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'short');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Lỗi từ parent'), findsOneWidget);
      expect(
        find.text(
          VPasswordValidator.defaultMinLengthPasswordMessage(
            VPasswordValidator.defaultMinLength,
          ),
        ),
        findsNothing,
      );
    });

    testWidgets('toggles obscureText when visibility icon is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VPasswordField(
              label: 'Mật khẩu',
            ),
          ),
        ),
      );

      TextField field() => tester.widget<TextField>(find.byType(TextField));
      expect(field().obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();
      expect(field().obscureText, isFalse);
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();
      expect(field().obscureText, isTrue);
    });

    testWidgets('custom suffixIcon replaces built-in toggle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VPasswordField(
              label: 'Mật khẩu',
              suffixIcon: Icon(Icons.lock),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);
      expect(find.byIcon(Icons.visibility), findsNothing);
    });

    testWidgets('onChanged is called on every keystroke', (tester) async {
      final values = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: VPasswordField(
              label: 'Mật khẩu',
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
            body: VPasswordField(
              label: 'Mật khẩu',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'short');
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text(
          VPasswordValidator.defaultMinLengthPasswordMessage(
            VPasswordValidator.defaultMinLength,
          ),
        ),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), '');
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text(
          VPasswordValidator.defaultMinLengthPasswordMessage(
            VPasswordValidator.defaultMinLength,
          ),
        ),
        findsNothing,
      );
    });
  });
}
