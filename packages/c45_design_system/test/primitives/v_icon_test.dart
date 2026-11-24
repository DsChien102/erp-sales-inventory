import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  group('VIcon', () {
    Widget wrap(Widget child) {
      return MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(body: child),
      );
    }

    testWidgets('without weight renders an Icon on the default Lucide family',
        (tester) async {
      await tester.pumpWidget(wrap(const VIcon(icon: VIcons.search)));

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon!.fontFamily, 'Lucide');
      expect(icon.icon!.codePoint, VIcons.search.value.codePoint);
    });

    testWidgets('weight renders the glyph from the per-weight family',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const VIcon(
            icon: VIcons.search,
            size: 32,
            weight: VIconWeight.light,
          ),
        ),
      );

      // Weighted icons bypass Icon to avoid runtime IconData (tree shaking).
      expect(find.byType(Icon), findsNothing);

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style!.fontFamily, 'packages/lucide_icons_flutter/Lucide300');
      expect(text.data, String.fromCharCode(VIcons.search.value.codePoint));
      expect(text.style!.fontSize, 32);
    });

    testWidgets('every weight maps to its own font family', (tester) async {
      const expected = {
        VIconWeight.thin: 'Lucide100',
        VIconWeight.extraLight: 'Lucide200',
        VIconWeight.light: 'Lucide300',
        VIconWeight.regular: 'Lucide400',
        VIconWeight.medium: 'Lucide500',
        VIconWeight.semiBold: 'Lucide600',
      };

      for (final entry in expected.entries) {
        await tester.pumpWidget(
          wrap(VIcon(icon: VIcons.check, weight: entry.key)),
        );

        expect(
          tester.widget<Text>(find.byType(Text)).style!.fontFamily,
          'packages/lucide_icons_flutter/${entry.value}',
          reason: 'weight ${entry.key.name}',
        );
      }
    });

    testWidgets('weighted glyph keeps the resolved size and color',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const VIcon(
            icon: VIcons.warning,
            iconSize: VIconSize.lg,
            iconColor: VIconColor.danger,
            weight: VIconWeight.medium,
          ),
        ),
      );

      final style = tester.widget<Text>(find.byType(Text)).style!;
      expect(style.fontSize, VIconSize.lg.value);
      expect(style.color, VColorScheme.light.danger);
      expect(
        tester.getSize(find.byType(SizedBox).first).height,
        VIconSize.lg.value,
      );
    });

    testWidgets('weight is ignored for legacy Material iconData',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const VIcon(
            // ignore: deprecated_member_use
            iconData: Icons.home,
            weight: VIconWeight.thin,
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.home);
      expect(icon.icon!.fontFamily, 'MaterialIcons');
    });

    testWidgets('weight is ignored for assetPath icons', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VIcon(
            assetPath: 'assets/icons/ic_calendar.png',
            weight: VIconWeight.semiBold,
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
      // The package ships no bundled image; only the widget choice matters here.
      tester.takeException();
    });
  });
}
