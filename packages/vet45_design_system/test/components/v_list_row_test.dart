import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('VListRow', () {
    testWidgets('navigation_shows_chevron', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VListRow(
            title: 'Tồn kho',
            type: VListRowType.navigation,
          ),
        ),
      );

      final iconFinder = find.byWidgetPredicate(
        (w) => w is VIcon && w.icon == VIcons.chevronRight,
      );
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('plain_has_no_chevron', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VListRow(
            title: 'Tồn kho',
            type: VListRowType.plain,
          ),
        ),
      );

      final iconFinder = find.byWidgetPredicate(
        (w) => w is VIcon && w.icon == VIcons.chevronRight,
      );
      expect(iconFinder, findsNothing);
    });

    testWidgets('tap_calls_onTap', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        wrap(
          VListRow(
            title: 'Tồn kho',
            onTap: () => tapped++,
          ),
        ),
      );

      await tester.tap(find.text('Tồn kho'));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    });

    testWidgets('disabled_ignores_tap', (tester) async {
      final handle = tester.ensureSemantics();
      var tapped = 0;
      await tester.pumpWidget(
        wrap(
          VListRow(
            title: 'Tồn kho',
            enabled: false,
            onTap: () => tapped++,
          ),
        ),
      );

      await tester.tap(find.text('Tồn kho'));
      await tester.pumpAndSettle();
      expect(tapped, 0);

      final semantics = tester.getSemantics(find.byType(VListRow));
      final isEnabled = semantics.hasFlag(SemanticsFlag.hasEnabledState) &&
          semantics.hasFlag(SemanticsFlag.isEnabled);
      expect(isEnabled, isFalse);
      handle.dispose();
    });

    testWidgets('shows_subtitle_and_trailing', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VListRow(
            title: 'Nhập hàng',
            subtitle: 'Nhận theo chứng từ',
            leading: VIcons.inventory,
            trailing: Text('12'),
          ),
        ),
      );

      expect(find.text('Nhập hàng'), findsOneWidget);
      expect(find.text('Nhận theo chứng từ'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.byType(VIconBox), findsOneWidget);
    });

    testWidgets('min_height_44', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VListRow(
            title: 'Đơn hàng',
          ),
        ),
      );

      final size = tester.getSize(find.byType(VListRow));
      expect(size.height, greaterThanOrEqualTo(VSpacing.minTouchTarget));
    });
  });
}
