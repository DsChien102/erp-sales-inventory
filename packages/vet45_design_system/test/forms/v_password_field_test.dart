import 'package:flutter/material.dart';
// ignore_for_file: deprecated_member_use
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

      await tester.tap(find.byTooltip('Hiện mật khẩu'));
      await tester.pump();
      expect(field().obscureText, isFalse);
      expect(find.byTooltip('Ẩn mật khẩu'), findsOneWidget);

      await tester.tap(find.byTooltip('Ẩn mật khẩu'));
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

    group('visibility toggle', () {
      Future<void> pump(WidgetTester tester) => tester.pumpWidget(
            MaterialApp(
              theme: VTheme.lightTheme,
              home: const Scaffold(body: VPasswordField(label: 'Mật khẩu')),
            ),
          );

      testWidgets('touch target is at least 44×44', (tester) async {
        await pump(tester);
        final size = tester.getSize(find.byType(IconButton));
        expect(size.width, greaterThanOrEqualTo(VSpacing.minTouchTarget));
        expect(size.height, greaterThanOrEqualTo(VSpacing.minTouchTarget));
      });

      testWidgets('name follows the obscured state', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester);
        expect(find.byTooltip('Hiện mật khẩu'), findsOneWidget);

        await tester.tap(find.byType(IconButton));
        await tester.pump();
        expect(find.byTooltip('Ẩn mật khẩu'), findsOneWidget);
        handle.dispose();
      });

      testWidgets('semantics node is a named button of at least 44×44',
          (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester);

        final node = tester.getSemantics(find.byType(IconButton));
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.label.isNotEmpty || node.tooltip.isNotEmpty, isTrue);
        expect(node.rect.width, greaterThanOrEqualTo(VSpacing.minTouchTarget));
        expect(node.rect.height, greaterThanOrEqualTo(VSpacing.minTouchTarget));
        handle.dispose();
      });

      testWidgets('field height is unchanged by the larger button', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: VTheme.lightTheme,
            home: const Scaffold(body: VPasswordField()),
          ),
        );
        expect(
          tester.getSize(find.byType(VPasswordField)).height,
          VDensity.fromMode(VDensityMode.comfortable).controlHeightMedium,
        );
      });
    });
  });
}
