import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VText', () {
    Widget wrap(Widget child) {
      return MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(body: child),
      );
    }

    testWidgets('default variant renders data', (tester) async {
      await tester.pumpWidget(wrap(const VText('Hello VText')));

      expect(find.text('Hello VText'), findsOneWidget);
      final text = tester.widget<Text>(find.text('Hello VText'));
      expect(text.style?.fontSize, VTypography.bodyDefault.fontSize);
    });

    testWidgets('custom color is applied', (tester) async {
      await tester.pumpWidget(
        wrap(VText('Colored', color: VColorScheme.light.danger)),
      );

      final text = tester.widget<Text>(find.text('Colored'));
      expect(text.style?.color, VColorScheme.light.danger);
    });

    testWidgets('variant maps to typography fontSize', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Column(
            children: [
              VText('H1', variant: VTextVariant.headingH1),
              VText('Caption', variant: VTextVariant.caption),
            ],
          ),
        ),
      );

      final h1 = tester.widget<Text>(find.text('H1'));
      final caption = tester.widget<Text>(find.text('Caption'));
      expect(h1.style?.fontSize, VTypography.headingH1.fontSize);
      expect(caption.style?.fontSize, VTypography.caption.fontSize);
    });

    testWidgets('mono variants use mono font family', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Column(
            children: [
              VText('Mono body', variant: VTextVariant.bodyDefaultMono),
              VText('Mono H3', variant: VTextVariant.headingH3Mono),
            ],
          ),
        ),
      );

      final body = tester.widget<Text>(find.text('Mono body'));
      final h3 = tester.widget<Text>(find.text('Mono H3'));
      expect(body.style?.fontFamily, VTypography.monoFontFamily);
      expect(h3.style?.fontFamily, VTypography.monoFontFamily);
      expect(body.style?.fontSize, VTypography.bodyDefaultMono.fontSize);
    });

    testWidgets('maxLines and overflow are forwarded', (tester) async {
      await tester.pumpWidget(
        wrap(
          const SizedBox(
            width: 40,
            child: VText(
              'Very long text that overflows',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });
  });
}
