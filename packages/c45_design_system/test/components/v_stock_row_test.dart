import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  group('VStockRow', () {
    Widget wrap(Widget child) {
      return MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(body: Center(child: child)),
      );
    }

    testWidgets('min_height_64', (tester) async {
      await tester.pumpWidget(
        wrap(
          VStockRow(
            title: 'Amox 500',
            subtitle: 'SP-000066',
            quantity: '46 hộp',
            onTap: () {},
          ),
        ),
      );

      final size = tester.getSize(find.byType(VStockRow));
      expect(size.height, greaterThanOrEqualTo(64.0));
    });

    testWidgets('quantity_mono_bold_16', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VStockRow(
            title: 'Amox 500',
            subtitle: 'SP-000066',
            quantity: '46 hộp',
          ),
        ),
      );

      final qtyText = tester.widget<Text>(find.text('46 hộp'));
      expect(qtyText.style?.fontSize, 16.0);
      expect(qtyText.style?.fontWeight, FontWeight.w700);
      expect(qtyText.style?.fontFamily, VTypography.monoFontFamily);
    });

    testWidgets('badge_below_quantity', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VStockRow(
            title: 'Amox 500',
            subtitle: 'SP-000066',
            quantity: '46 hộp',
            badge: VBadge(
              label: 'Tồn thấp',
              tone: VComponentTone.warning,
              showDot: true,
            ),
          ),
        ),
      );

      final qtyCenter = tester.getCenter(find.text('46 hộp'));
      final badgeCenter = tester.getCenter(find.byType(VBadge));
      expect(badgeCenter.dy, greaterThan(qtyCenter.dy));
    });

    testWidgets('has_chevron', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VStockRow(
            title: 'Amox 500',
            subtitle: 'SP-000066',
            quantity: '46 hộp',
          ),
        ),
      );

      final icon = tester.widget<VIcon>(find.byType(VIcon));
      expect(icon.icon, VIcons.chevronRight);
    });

    testWidgets('semantics_button_label', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          wrap(
            VStockRow(
              title: 'Enrofloxacin 10%',
              subtitle: 'SP-000091',
              quantity: '0 chai',
              badge: const VBadge(
                label: 'Hết hàng',
                tone: VComponentTone.danger,
                showDot: true,
                hollowDot: true,
              ),
              onTap: () {},
            ),
          ),
        );

        final semanticsWidget = tester.widget<Semantics>(
          find
              .descendant(
                of: find.byType(VStockRow),
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is Semantics &&
                      w.properties.button == true &&
                      (w.properties.label?.contains('Enrofloxacin 10%') ??
                          false),
                ),
              )
              .first,
        );
        expect(
          semanticsWidget.properties.label,
          'Enrofloxacin 10%, 0 chai, Hết hàng',
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
