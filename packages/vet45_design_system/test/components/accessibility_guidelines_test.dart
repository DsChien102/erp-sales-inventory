import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_design_system/src/components/v_numeric_keypad_grid.dart';

/// Touch-target and naming guidelines for the controls that were fixed in 10-6.
void main() {
  testWidgets('tappable design-system controls are ≥ 44pt and named', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(
          appBar: const VAppBar(title: 'Kiểm tra', showBackButton: false),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VChip(label: 'Tồn kho thấp', onTap: () {}, onRemove: () {}),
                VIconBox(
                  icon: VIcons.camera,
                  size: 24,
                  iconSize: 16,
                  semanticLabel: 'Chụp ảnh',
                  onTap: () {},
                ),
                VSwipeReveal(
                  actionExtent: 100,
                  semanticActions: [
                    VSwipeSemanticAction(label: 'Xóa', onInvoke: () {}),
                  ],
                  actionsBuilder: (context, close) => SizedBox(
                    width: 100,
                    child: TextButton(onPressed: close, child: const Text('Xóa')),
                  ),
                  child: const SizedBox(
                    height: 56,
                    child: Center(child: Text('Dòng hàng')),
                  ),
                ),
                VNumericKeypadGrid(
                  mode: VNumericKeypadMode.quantity,
                  allowDecimal: true,
                  onKey: (_) {},
                  onBackspace: () {},
                ),
              ],
            ),
          ),
          bottomNavigationBar: VBottomNavigationBar(
            currentIndex: 0,
            onTap: (_) {},
            items: const [
              VBottomNavigationItem(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
              VBottomNavigationItem(icon: Icon(Icons.receipt_long_outlined), label: 'Đơn hàng'),
            ],
          ),
        ),
      ),
    );

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('VSideNavigation controls are ≥ 44pt and named', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(
          body: VSideNavigation(
            selected: const (0, null),
            onSelect: (_, _) {},
            items: const [
              VSideNavigationItem(
                icon: Icon(Icons.home_outlined),
                label: 'Trang chủ',
              ),
              VSideNavigationItem(
                icon: Icon(Icons.more_horiz_rounded),
                label: 'Thêm',
                children: [
                  VSideNavigationItem(
                    icon: SizedBox.shrink(),
                    label: 'Kho',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
