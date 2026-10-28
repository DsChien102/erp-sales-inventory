import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VSideNavigation', () {
    List<VSideNavigationItem> buildItems({
      bool lastMainEnabled = true,
      bool lastChildEnabled = true,
    }) => [
      const VSideNavigationItem(
        icon: Icon(Icons.home_outlined),
        label: 'Trang chủ',
      ),
      const VSideNavigationItem(
        icon: Icon(Icons.receipt_long_outlined),
        label: 'Đơn hàng',
      ),
      VSideNavigationItem(
        icon: const Icon(Icons.more_horiz_rounded),
        label: 'Thêm',
        enabled: lastMainEnabled,
        children: [
          const VSideNavigationItem(
            label: 'Kho',
          ),
          VSideNavigationItem(
            label: 'Thiết lập',
            enabled: lastChildEnabled,
          ),
        ],
      ),
    ];

    Future<void> pumpNav(
      WidgetTester tester, {
      (int, int?) selected = (0, null),
      bool lastMainEnabled = true,
      bool lastChildEnabled = true,
      void Function(int, int?)? onSelect,
      Widget? header,
      Widget? footer,
      double width = 240,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: VSideNavigation(
              selected: selected,
              items: buildItems(
                lastMainEnabled: lastMainEnabled,
                lastChildEnabled: lastChildEnabled,
              ),
              onSelect: onSelect ?? (_, _) {},
              header: header,
              footer: footer,
              width: width,
            ),
          ),
        ),
      );
    }

    testWidgets('renders all main items and children labels', (tester) async {
      await pumpNav(tester);

      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Đơn hàng'), findsOneWidget);
      expect(find.text('Thêm'), findsOneWidget);
      expect(find.text('Kho'), findsOneWidget);
      expect(find.text('Thiết lập'), findsOneWidget);
    });

    testWidgets('tap on main item triggers onSelect with (item, null)', (tester) async {
      final selections = <(int, int?)>[];
      await pumpNav(tester, onSelect: (i, c) => selections.add((i, c)));

      await tester.tap(find.text('Đơn hàng'));
      expect(selections, [(1, null)]);
    });

    testWidgets('tap on child item triggers onSelect with (item, child)', (tester) async {
      final selections = <(int, int?)>[];
      await pumpNav(tester, onSelect: (i, c) => selections.add((i, c)));

      await tester.tap(find.text('Kho'));
      expect(selections, [(2, 0)]);
    });

    testWidgets('disabled main item and child do not call onSelect', (tester) async {
      final selections = <(int, int?)>[];
      await pumpNav(
        tester,
        lastMainEnabled: false,
        lastChildEnabled: false,
        onSelect: (i, c) => selections.add((i, c)),
      );

      await tester.tap(find.text('Thêm'));
      expect(selections, isEmpty);

      await tester.tap(find.text('Thiết lập'));
      expect(selections, isEmpty);
    });

    testWidgets('exposes semantics button role and selected state', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpNav(tester, selected: (2, 0));

      final selectedChild = tester.getSemantics(find.text('Kho'));
      expect(selectedChild.label, 'Kho');
      expect(selectedChild.flagsCollection.isButton, isTrue);
      expect(selectedChild.flagsCollection.isSelected, Tristate.isTrue);

      final unselectedChild = tester.getSemantics(find.text('Thiết lập'));
      expect(unselectedChild.flagsCollection.isButton, isTrue);
      expect(unselectedChild.flagsCollection.isSelected, Tristate.isFalse);

      final parentItem = tester.getSemantics(find.text('Thêm'));
      expect(parentItem.flagsCollection.isButton, isTrue);
      expect(parentItem.flagsCollection.isSelected, Tristate.isTrue);

      final otherMain = tester.getSemantics(find.text('Trang chủ'));
      expect(otherMain.flagsCollection.isButton, isTrue);
      expect(otherMain.flagsCollection.isSelected, Tristate.isFalse);

      handle.dispose();
    });

    testWidgets('renders header and footer when provided', (tester) async {
      await pumpNav(
        tester,
        header: const Text('My Organization'),
        footer: const Text('Đăng xuất'),
      );

      expect(find.text('My Organization'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsOneWidget);
    });

    testWidgets('Tab moves focus through items and Enter key activates onSelect', (tester) async {
      final selections = <(int, int?)>[];
      await pumpNav(tester, onSelect: (i, c) => selections.add((i, c)));

      // Send Tab to focus first element ('Trang chủ')
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Press Enter to activate focused item
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(selections, [(0, null)]);

      // Send Tab again to move to next item ('Đơn hàng')
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(selections, [(0, null), (1, null)]);
    });
  });
}
