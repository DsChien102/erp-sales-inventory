import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/inventory/presentation/patterns/k4_result_page.dart';
import '../../support/inventory_test_surface.dart';

void main() {
  Widget wrap(Widget child, {Size size = const Size(390, 844)}) {
    useInventoryTestSurface(size);
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child,
      ),
    );
  }

  group('K4ResultPage', () {
    testWidgets('k4_no_back_button', (tester) async {
      await tester.pumpWidget(
        wrap(
          const K4ResultPage(
            title: 'Nhận hàng thành công',
            description: 'Đã nhập kho 2 mặt hàng.',
          ),
        ),
      );

      final scaffold = tester.widget<VPageScaffold>(find.byType(VPageScaffold));
      expect(scaffold.showBackButton, isFalse);
    });

    testWidgets('k4_stock_change_line', (tester) async {
      await tester.pumpWidget(
        wrap(
          const K4ResultPage(
            title: 'Nhận hàng thành công',
            description: 'Đã cập nhật tồn kho.',
            stockChanges: [
              K4StockChange(
                product: 'Nobivac DHPPi',
                before: '120 hộp',
                after: '122 hộp',
              ),
            ],
          ),
        ),
      );

      expect(find.text('Tồn kho đã đổi'), findsOneWidget);
      expect(find.text('Nobivac DHPPi 120 hộp → 122 hộp'), findsOneWidget);
    });

    testWidgets('k4_has_no_bottom_bar', (tester) async {
      await tester.pumpWidget(
        wrap(
          const K4ResultPage(
            title: 'Thành công',
            description: 'Đã lưu.',
          ),
          size: const Size(390, 844),
        ),
      );

      final scaffold = tester.widget<VPageScaffold>(find.byType(VPageScaffold));
      expect(scaffold.bottomBar, isNull);
    });
  });
}
