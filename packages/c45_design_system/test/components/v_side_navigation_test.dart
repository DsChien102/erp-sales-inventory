import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  group('VSideNavigation', () {
    const mainLabels = ['Trang chủ', 'Đơn hàng'];

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
        menuTitle: 'Quản lý cửa hàng',
        enabled: lastMainEnabled,
        children: [
          const VSideNavigationItem(
            label: 'Kho',
            description: 'Tồn kho, phiếu nhập, điều chỉnh',
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
      double? width,
      TextScaler? textScaler,
    }) async {
      Widget nav = Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          height: 700,
          child: width == null
              ? VSideNavigation(
                  selected: selected,
                  items: buildItems(
                    lastMainEnabled: lastMainEnabled,
                    lastChildEnabled: lastChildEnabled,
                  ),
                  onSelect: onSelect ?? (_, _) {},
                  header: header,
                  footer: footer,
                )
              : VSideNavigation(
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
      );
      if (textScaler != null) {
        final inner = nav;
        nav = Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: inner,
          ),
        );
      }
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(theme: VTheme.lightTheme, home: Scaffold(body: nav)),
      );
    }

    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.text('Thêm'));
      await tester.pumpAndSettle();
    }

    testWidgets('rail is 84 wide with right hairline', (tester) async {
      await pumpNav(tester);
      expect(tester.getSize(find.byType(VSideNavigation)).width, 84);
    });

    testWidgets('renders main items; children appear only in the menu', (tester) async {
      await pumpNav(tester);

      for (final l in mainLabels) {
        expect(find.text(l), findsOneWidget);
      }
      expect(find.text('Thêm'), findsOneWidget);
      expect(find.text('Kho'), findsNothing);
      expect(find.text('Quản lý cửa hàng'), findsNothing);
    });

    testWidgets('item with children sits below spacer and opens menu', (tester) async {
      await pumpNav(tester);

      final orders = tester.getTopLeft(find.text('Đơn hàng')).dy;
      final more = tester.getTopLeft(find.text('Thêm')).dy;
      expect(more, greaterThan(orders + 100));

      expect(find.text('Kho'), findsNothing);
      await openMenu(tester);
      expect(find.text('Kho'), findsOneWidget);
      expect(find.text('Thiết lập'), findsOneWidget);
      expect(find.text('Quản lý cửa hàng'), findsOneWidget);
    });

    testWidgets('tapping parent does not call onSelect; tapping it again closes menu', (tester) async {
      final selections = <(int, int?)>[];
      await pumpNav(tester, onSelect: (i, c) => selections.add((i, c)));

      await openMenu(tester);
      expect(find.text('Kho'), findsOneWidget);
      expect(selections, isEmpty);

      await openMenu(tester);
      expect(find.text('Kho'), findsNothing);
      expect(selections, isEmpty);
    });

    testWidgets('tap on main item triggers onSelect with (item, null)', (tester) async {
      final selections = <(int, int?)>[];
      await pumpNav(tester, onSelect: (i, c) => selections.add((i, c)));

      await tester.tap(find.text('Đơn hàng'));
      expect(selections, [(1, null)]);
    });

    testWidgets('tap child calls onSelect(2, 0) and closes menu', (tester) async {
      final selections = <(int, int?)>[];
      await pumpNav(tester, onSelect: (i, c) => selections.add((i, c)));

      await openMenu(tester);
      await tester.tap(find.text('Kho'));
      await tester.pumpAndSettle();

      expect(selections, [(2, 0)]);
      expect(find.text('Kho'), findsNothing);
    });

    testWidgets('Escape and outside tap close menu', (tester) async {
      await pumpNav(tester);

      await openMenu(tester);
      expect(find.text('Kho'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Kho'), findsNothing);

      await openMenu(tester);
      expect(find.text('Kho'), findsOneWidget);
      await tester.tapAt(const Offset(800, 100));
      await tester.pumpAndSettle();
      expect(find.text('Kho'), findsNothing);
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
      await tester.pumpAndSettle();
      expect(selections, isEmpty);
      expect(find.text('Kho'), findsNothing); // tab tắt không mở menu

      await pumpNav(
        tester,
        lastChildEnabled: false,
        onSelect: (i, c) => selections.add((i, c)),
      );
      await openMenu(tester);
      await tester.tap(find.text('Thiết lập'));
      await tester.pumpAndSettle();
      expect(selections, isEmpty);
    });

    testWidgets('exposes semantics button role and selected state', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpNav(tester, selected: (2, 0));
      await openMenu(tester);

      final selectedChild = tester.getSemantics(find.text('Kho'));
      expect(selectedChild.label, contains('Kho'));
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

    testWidgets('parent with selected child is highlighted', (tester) async {
      await pumpNav(tester, selected: (2, 1));
      final colors = VColorScheme.light;

      Color? tabBg(String label) {
        final box = tester.widget<Container>(
          find.ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.decoration is BoxDecoration && (w.decoration! as BoxDecoration).color != null,
            ),
          ).first,
        );
        return (box.decoration! as BoxDecoration).color;
      }

      expect(tabBg('Thêm'), colors.surfaceBrand);

      final handle = tester.ensureSemantics();
      await openMenu(tester);
      expect(tester.getSemantics(find.text('Thiết lập')).flagsCollection.isSelected, Tristate.isTrue);
      expect(tester.getSemantics(find.text('Kho')).flagsCollection.isSelected, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('menu shows description under child label', (tester) async {
      await pumpNav(tester);
      await openMenu(tester);
      expect(find.text('Tồn kho, phiếu nhập, điều chỉnh'), findsOneWidget);
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

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selections, [(0, null)]);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selections, [(0, null), (1, null)]);
    });

    testWidgets('has surface background and right hairline', (tester) async {
      await pumpNav(tester);
      final colors = VColorScheme.light;
      final box = tester.widget<Container>(
        find.descendant(
          of: find.byType(VSideNavigation),
          matching: find.byWidgetPredicate(
            (w) => w is Container && w.decoration is BoxDecoration && (w.decoration! as BoxDecoration).border != null,
          ),
        ).first,
      );
      final deco = box.decoration! as BoxDecoration;
      expect(deco.color, colors.surface);
      expect((deco.border! as Border).right.color, colors.borderDefault);
    });

    testWidgets('tab min height 60, menu item min height 44', (tester) async {
      await pumpNav(tester);
      for (final label in ['Trang chủ', 'Đơn hàng', 'Thêm']) {
        final item = find.ancestor(of: find.text(label), matching: find.byType(MergeSemantics)).first;
        expect(tester.getSize(item).height, greaterThanOrEqualTo(60), reason: label);
      }
      await openMenu(tester);
      for (final label in ['Kho', 'Thiết lập']) {
        final item = find.ancestor(of: find.text(label), matching: find.byType(MergeSemantics)).first;
        expect(tester.getSize(item).height, greaterThanOrEqualTo(VSpacing.minTouchTarget), reason: label);
      }
    });

    testWidgets('label clamps text scale to 1.3 and stays on one line', (tester) async {
      await pumpNav(tester, textScaler: const TextScaler.linear(2));
      await openMenu(tester);
      expect(tester.takeException(), isNull);
      for (final label in ['Trang chủ', 'Đơn hàng', 'Thêm', 'Kho', 'Thiết lập']) {
        expect(tester.widget<Text>(find.text(label)).maxLines, 1, reason: label);
      }
      // 1.3 × 11 = 14.3 chứ không phải 22
      final fontSize = tester.getSize(find.text('Đơn hàng')).height;
      expect(fontSize, lessThan(22));
    });

    testWidgets('menu removed when rail unmounted', (tester) async {
      await pumpNav(tester);
      await openMenu(tester);
      expect(find.text('Kho'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(theme: VTheme.lightTheme, home: const Scaffold(body: SizedBox())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kho'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('VSideNavigationAction destructive uses danger color', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 68,
                child: VSideNavigationAction(
                  icon: VIcons.logout,
                  label: 'Đăng xuất',
                  destructive: true,
                  onTap: () => taps++,
                ),
              ),
            ),
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('Đăng xuất'));
      expect(text.style!.color, VColorScheme.light.danger);
      await tester.tap(find.text('Đăng xuất'));
      expect(taps, 1);
    });
  });
}
