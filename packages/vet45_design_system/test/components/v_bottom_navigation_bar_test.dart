import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VBottomNavigationBar', () {
    const labels = ['Trang chủ', 'Đơn hàng', 'Sản phẩm'];

    List<VBottomNavigationItem> buildItems({bool lastEnabled = true}) => [
      const VBottomNavigationItem(
        icon: Icon(Icons.home_outlined),
        label: 'Trang chủ',
      ),
      const VBottomNavigationItem(
        icon: Icon(Icons.receipt_long_outlined),
        label: 'Đơn hàng',
      ),
      VBottomNavigationItem(
        icon: const Icon(Icons.inventory_2_outlined),
        label: 'Sản phẩm',
        enabled: lastEnabled,
      ),
    ];

    Future<void> pumpBar(
      WidgetTester tester, {
      int currentIndex = 0,
      bool lastEnabled = true,
      ValueChanged<int>? onTap,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: VBottomNavigationBar(
              currentIndex: currentIndex,
              items: buildItems(lastEnabled: lastEnabled),
              onTap: onTap ?? (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets('shows a text label for every item', (tester) async {
      await pumpBar(tester);

      for (final label in labels) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('exposes name, button role and selected state', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpBar(tester, currentIndex: 1);

      final selected = tester.getSemantics(find.text('Đơn hàng'));
      expect(selected.label, 'Đơn hàng');
      expect(selected.flagsCollection.isButton, isTrue);
      expect(selected.flagsCollection.isSelected, Tristate.isTrue);

      final other = tester.getSemantics(find.text('Trang chủ'));
      expect(other.label, 'Trang chủ');
      expect(other.flagsCollection.isButton, isTrue);
      expect(other.flagsCollection.isSelected, Tristate.isFalse);

      handle.dispose();
    });

    testWidgets('tap calls onTap with index; disabled item does not', (tester) async {
      final taps = <int>[];
      await pumpBar(tester, lastEnabled: false, onTap: taps.add);

      await tester.tap(find.text('Đơn hàng'));
      expect(taps, [1]);

      await tester.tap(find.text('Sản phẩm'));
      expect(taps, [1]);
    });

    testWidgets('label colour: selected = primary, others = textSecondary', (tester) async {
      await pumpBar(tester, currentIndex: 0);

      final colors = VColorScheme.light;
      Color labelColor(String label) => tester.widget<Text>(find.text(label)).style!.color!;

      expect(labelColor('Trang chủ'), colors.primary);
      expect(labelColor('Đơn hàng'), colors.textSecondary);
      expect(labelColor('Sản phẩm'), colors.textSecondary);
    });

    group('bottom inset', () {
      Future<void> pumpWithInset(WidgetTester tester, double inset) {
        return tester.pumpWidget(
          MaterialApp(
            theme: VTheme.lightTheme,
            builder: (context, app) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: EdgeInsets.only(bottom: inset),
              ),
              child: app!,
            ),
            home: Scaffold(
              bottomNavigationBar: VBottomNavigationBar(
                currentIndex: 0,
                items: buildItems(),
                onTap: (_) {},
              ),
            ),
          ),
        );
      }

      double clearance(WidgetTester tester) =>
          tester.getBottomLeft(find.byType(VBottomNavigationBar)).dy -
          tester.getBottomLeft(find.text('Trang chủ')).dy;

      testWidgets('keeps labels clear of the home indicator', (tester) async {
        await pumpWithInset(tester, 34);
        expect(clearance(tester), greaterThanOrEqualTo(34));
      });

      testWidgets('uses the full inset, not a fraction of it', (tester) async {
        await pumpWithInset(tester, 34);
        final withInset = tester.getSize(find.byType(VBottomNavigationBar)).height;
        await pumpWithInset(tester, 0);
        final without = tester.getSize(find.byType(VBottomNavigationBar)).height;

        // 4 top + 48 tab + 34 inset (+1 hairline) vs 4 + 48 + 12 (+1).
        expect(withInset - without, closeTo(34 - 12, 0.5));
      });

      testWidgets('tab cells are at least 48 high', (tester) async {
        await pumpWithInset(tester, 0);
        final cell = find.ancestor(
          of: find.text('Trang chủ'),
          matching: find.byType(InkWell),
        );
        expect(tester.getSize(cell.first).height, greaterThanOrEqualTo(48));
      });
    });
  });
}
