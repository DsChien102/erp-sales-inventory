import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

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

    testWidgets('link keeps a minimum touch target', (tester) async {
      await tester.pumpWidget(
        wrap(
          VButton(
            label: 'Link',
            variant: VButtonVariant.link,
            onPressed: () {},
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(VButton)).height,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester.getSize(find.byType(VButton)).width,
        greaterThanOrEqualTo(44),
      );
      expect(tester.getSize(find.text('Link')).height, lessThan(44));
    });

    testWidgets('link exposes tap action to semantics when enabled and omits when disabled', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;

      await tester.pumpWidget(
        wrap(
          VButton(
            label: 'Link',
            variant: VButtonVariant.link,
            onPressed: () => taps++,
          ),
        ),
      );

      tester.semantics.tap(find.semantics.byLabel('Link'));
      await tester.pump();
      expect(taps, 1);

      await tester.pumpWidget(
        wrap(
          const VButton(
            label: 'Link',
            variant: VButtonVariant.link,
            onPressed: null,
          ),
        ),
      );

      final node = tester.getSemantics(find.text('Link'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);

      handle.dispose();
    });

    testWidgets('leading and trailing VIcons render', (tester) async {
      await tester.pumpWidget(
        wrap(
          VButton(
            label: 'With icons',
            variant: VButtonVariant.link,
            leading: VIcons.info,
            trailing: VIcons.arrowForward,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(VIcon), findsNWidgets(2));
      expect(find.text('With icons'), findsOneWidget);
    });

    testWidgets('deprecated Widget icons still render', (tester) async {
      await tester.pumpWidget(
        wrap(
          VButton(
            label: 'Legacy icons',
            variant: VButtonVariant.link,
            // ignore: deprecated_member_use
            leadingIcon: const Icon(Icons.link, key: Key('leading')),
            // ignore: deprecated_member_use
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

  group('VButton.icon', () {
    testWidgets('renders VIcon without label', (tester) async {
      await tester.pumpWidget(
        wrap(VButton.icon(icon: VIcons.add, onPressed: () {})),
      );

      expect(find.byType(VIcon), findsOneWidget);
      expect(find.byType(VText), findsNothing);
    });
  });

  group('VButton expandText', () {
    testWidgets('expanded text respects textAlign start when fullWidth', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 320,
            child: VButton(
              label: 'Aligned',
              fullWidth: true,
              expandText: true,
              textAlign: TextAlign.start,
              leading: VIcons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      final text = tester.widget<VText>(find.byType(VText));
      expect(text.data, 'Aligned');
      expect(text.textAlign, TextAlign.start);
      expect(find.byType(VIcon), findsOneWidget);
    });
  });
}
