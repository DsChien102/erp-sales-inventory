import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VChip', () {
    final colors = VColorScheme.light;

    Widget wrap(Widget child) {
      return MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(body: child),
      );
    }

    BoxDecoration decorationOf(WidgetTester tester) {
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(VChip),
          matching: find.byType(Container),
        ).first,
      );
      return container.decoration! as BoxDecoration;
    }

    Color labelColorOf(WidgetTester tester, String label) {
      return tester.widget<Text>(find.text(label)).style!.color!;
    }

    testWidgets('defaults to neutral tone', (tester) async {
      await tester.pumpWidget(wrap(const VChip(label: 'Neutral')));

      final decoration = decorationOf(tester);
      expect(decoration.color, colors.surfaceAlt);
      expect(decoration.border!.top.color, colors.borderStrong);
      expect(labelColorOf(tester, 'Neutral'), colors.textPrimary);
    });

    testWidgets('primary tone uses surfaceBrand, textBrand and borderBrand',
        (tester) async {
      await tester.pumpWidget(
        wrap(const VChip(label: 'Primary', tone: VComponentTone.primary)),
      );

      final decoration = decorationOf(tester);
      expect(decoration.color, colors.surfaceBrand);
      expect(decoration.border!.top.color, colors.borderBrand);
      expect(labelColorOf(tester, 'Primary'), colors.textBrand);
    });

    testWidgets('semantic tones border with their own foreground color',
        (tester) async {
      await tester.pumpWidget(
        wrap(const VChip(label: 'Danger', tone: VComponentTone.danger)),
      );

      final decoration = decorationOf(tester);
      expect(decoration.color, colors.dangerBg);
      expect(decoration.border!.top.color, colors.danger);
      expect(labelColorOf(tester, 'Danger'), colors.danger);
    });

    testWidgets('ambient VComponentScope tone is inherited', (tester) async {
      await tester.pumpWidget(
        wrap(
          vProvideComponentScope(
            tone: VComponentTone.warning,
            child: const VChip(label: 'Ambient'),
          ),
        ),
      );

      expect(decorationOf(tester).color, colors.warningBg);
      expect(labelColorOf(tester, 'Ambient'), colors.warning);
    });

    testWidgets('local tone wins over ambient scope', (tester) async {
      await tester.pumpWidget(
        wrap(
          vProvideComponentScope(
            tone: VComponentTone.warning,
            child: const VChip(label: 'Local', tone: VComponentTone.info),
          ),
        ),
      );

      expect(decorationOf(tester).color, colors.infoBg);
      expect(labelColorOf(tester, 'Local'), colors.info);
    });

    testWidgets('deprecated selected bridges to primary tone', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VChip(
            label: 'Selected',
            // ignore: deprecated_member_use
            selected: true,
          ),
        ),
      );

      expect(decorationOf(tester).color, colors.surfaceBrand);
      expect(labelColorOf(tester, 'Selected'), colors.textBrand);
    });

    testWidgets('deprecated emphasis bridges to a tone', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Column(
            children: [
              VChip(
                label: 'Strong',
                // ignore: deprecated_member_use
                emphasis: VComponentEmphasis.strong,
              ),
              VChip(
                label: 'Subtle',
                // ignore: deprecated_member_use
                emphasis: VComponentEmphasis.subtle,
              ),
            ],
          ),
        ),
      );

      expect(labelColorOf(tester, 'Strong'), colors.textBrand);
      expect(labelColorOf(tester, 'Subtle'), colors.textPrimary);
    });

    testWidgets('explicit tone wins over deprecated selected', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VChip(
            label: 'Both',
            tone: VComponentTone.danger,
            // ignore: deprecated_member_use
            selected: true,
          ),
        ),
      );

      expect(decorationOf(tester).color, colors.dangerBg);
    });

    testWidgets('disabled chip is dimmed and does not fire onTap',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          VChip(
            label: 'Disabled',
            enabled: false,
            onTap: () => taps++,
          ),
        ),
      );

      expect(find.byType(Opacity), findsWidgets);
      await tester.tap(find.text('Disabled'));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('icon and remove control never exceed the label line height',
        (tester) async {
      final lineHeight =
          VTypography.bodySmall.fontSize! * VTypography.bodySmall.height!;

      await tester.pumpWidget(
        wrap(
          VChip(
            label: 'Tag',
            icon: VIcons.tag,
            onRemove: () {},
          ),
        ),
      );

      final labelHeight = tester.getSize(find.text('Tag')).height;
      expect(tester.getSize(find.byType(VIcon)).height, lessThanOrEqualTo(labelHeight));
      expect(
        tester.getSize(find.byIcon(Icons.close)).height,
        lessThanOrEqualTo(labelHeight),
      );
      expect(labelHeight, lineHeight);
    });

    testWidgets('onRemove shows a dismiss control that fires', (tester) async {
      var removed = 0;
      await tester.pumpWidget(
        wrap(
          VChip(
            label: 'Tag',
            tone: VComponentTone.info,
            onRemove: () => removed++,
          ),
        ),
      );

      final removeButton = find.byIcon(Icons.close);
      expect(removeButton, findsOneWidget);
      expect(tester.widget<Icon>(removeButton).color, colors.info);

      await tester.tap(removeButton);
      await tester.pump();
      expect(removed, 1);
    });
  });
}
