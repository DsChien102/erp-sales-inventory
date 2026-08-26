import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  group('VButton link', () {
    testWidgets('renders label without Material splash padding chrome', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          VButton(
            label: 'Forgot password?',
            variant: VButtonVariant.link,
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('disabled does not invoke onPressed', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        wrap(
          VButton(
            label: 'Disabled link',
            variant: VButtonVariant.link,
            onPressed: () => pressed++,
            enabled: false,
          ),
        ),
      );

      await tester.tap(find.text('Disabled link'));
      await tester.pump();
      expect(pressed, 0);
    });

    testWidgets('leading and trailing icons render', (tester) async {
      await tester.pumpWidget(
        wrap(
          VButton(
            label: 'With icons',
            variant: VButtonVariant.link,
            leadingIcon: const Icon(Icons.link, key: Key('leading')),
            trailingIcon: const Icon(Icons.arrow_outward, key: Key('trailing')),
            onPressed: () {},
          ),
        ),
      );

      expect(find.byKey(const Key('leading')), findsOneWidget);
      expect(find.byKey(const Key('trailing')), findsOneWidget);
    });

    testWidgets('keyboard activate invokes onPressed', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        wrap(
          VButton(
            label: 'Focus link',
            variant: VButtonVariant.link,
            onPressed: () => pressed++,
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(pressed, 1);
    });
  });
}
