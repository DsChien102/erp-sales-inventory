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

  group('VQuickActionButton', () {
    testWidgets('tap_calls', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        wrap(
          VQuickActionButton(
            icon: VIcons.inventory,
            label: 'Nhập hàng',
            onPressed: () => pressed++,
          ),
        ),
      );

      await tester.tap(find.text('Nhập hàng'));
      await tester.pumpAndSettle();
      expect(pressed, 1);
    });

    testWidgets('null_onPressed_is_disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          const VQuickActionButton(
            icon: VIcons.inventory,
            label: 'Nhập hàng',
            onPressed: null,
          ),
        ),
      );

      await tester.tap(find.text('Nhập hàng'));
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(find.byType(VQuickActionButton));
      final isEnabled = semantics.hasFlag(SemanticsFlag.hasEnabledState) &&
          semantics.hasFlag(SemanticsFlag.isEnabled);
      expect(isEnabled, isFalse);
      handle.dispose();
    });

    testWidgets('size_at_least_44', (tester) async {
      await tester.pumpWidget(
        wrap(
          VQuickActionButton(
            icon: VIcons.inventory,
            label: 'Nhập hàng',
            onPressed: () {},
          ),
        ),
      );

      final size = tester.getSize(find.byType(VQuickActionButton));
      expect(size.width, greaterThanOrEqualTo(VSpacing.minTouchTarget));
      expect(size.height, greaterThanOrEqualTo(VSpacing.minTouchTarget));
    });
  });
}
