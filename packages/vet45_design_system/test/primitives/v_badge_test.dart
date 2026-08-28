import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VBadge', () {
    final colors = VColorScheme.light;

    Widget wrap(Widget child) {
      return MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(body: child),
      );
    }

    Color backgroundOf(WidgetTester tester) {
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(VBadge),
          matching: find.byType(Container),
        ).first,
      );
      return (container.decoration! as BoxDecoration).color!;
    }

    Color labelColorOf(WidgetTester tester, String label) {
      return tester.widget<Text>(find.text(label)).style!.color!;
    }

    testWidgets('soft variant uses tinted surface and tone foreground',
        (tester) async {
      await tester.pumpWidget(
        wrap(const VBadge(label: 'Soft', tone: VComponentTone.danger)),
      );

      expect(backgroundOf(tester), colors.dangerBg);
      expect(labelColorOf(tester, 'Soft'), colors.danger);
    });

    testWidgets('strong variant fills with tone and inverts foreground',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const VBadge(
            label: 'Strong',
            tone: VComponentTone.danger,
            variant: VBadgeVariant.strong,
          ),
        ),
      );

      expect(backgroundOf(tester), colors.danger);
      expect(labelColorOf(tester, 'Strong'), colors.textInverse);
    });

    testWidgets('neutral tone maps to surfaceAlt and textPrimary',
        (tester) async {
      await tester.pumpWidget(wrap(const VBadge(label: 'Neutral')));

      expect(backgroundOf(tester), colors.surfaceAlt);
      expect(labelColorOf(tester, 'Neutral'), colors.textPrimary);
    });

    testWidgets('ambient VComponentScope tone is inherited', (tester) async {
      await tester.pumpWidget(
        wrap(
          vProvideComponentScope(
            tone: VComponentTone.warning,
            child: const VBadge(label: 'Ambient'),
          ),
        ),
      );

      expect(backgroundOf(tester), colors.warningBg);
      expect(labelColorOf(tester, 'Ambient'), colors.warning);
    });

    testWidgets('local tone wins over ambient scope', (tester) async {
      await tester.pumpWidget(
        wrap(
          vProvideComponentScope(
            tone: VComponentTone.warning,
            child: const VBadge(label: 'Local', tone: VComponentTone.info),
          ),
        ),
      );

      expect(backgroundOf(tester), colors.infoBg);
      expect(labelColorOf(tester, 'Local'), colors.info);
    });

    testWidgets('deprecated status still resolves a tone', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VBadge(
            label: 'Legacy',
            // ignore: deprecated_member_use
            status: VBadgeStatus.overdue,
          ),
        ),
      );

      expect(backgroundOf(tester), colors.dangerBg);
      expect(labelColorOf(tester, 'Legacy'), colors.danger);
    });

    testWidgets('dot and icon follow the foreground color', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VBadge(
            label: 'Icon',
            tone: VComponentTone.success,
            variant: VBadgeVariant.strong,
            iconData: Icons.check_rounded,
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.check_rounded));
      expect(icon.color, colors.textInverse);
    });

    testWidgets('semanticLabel overrides the announced label', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VBadge(
            label: 'Paid',
            tone: VComponentTone.success,
            semanticLabel: 'Trạng thái: đã thanh toán',
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(
        find.descendant(
          of: find.byType(VBadge),
          matching: find.byType(Semantics),
        ).first,
      );
      expect(semantics.properties.label, 'Trạng thái: đã thanh toán');
    });
  });
}
