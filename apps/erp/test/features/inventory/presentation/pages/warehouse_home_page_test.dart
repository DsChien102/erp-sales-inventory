import 'package:erp/features/inventory/data/inventory_repository.dart';
import 'package:erp/features/inventory/logic/warehouse_home_cubit.dart';
import 'package:erp/features/inventory/presentation/pages/warehouse_home_page.dart';
import 'package:erp/features/inventory/presentation/widgets/warehouse_start_new_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('WarehouseHomePage', () {
    testWidgets('renders all sections and tasks correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = WarehouseHomeCubit(repository: const InventoryRepository());
      await cubit.load();
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: WarehouseHomePage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // Check AppBar
      expect(find.text('Kho'), findsOneWidget);

      // Check Search bar widget & hint text
      expect(
        find.byWidgetPredicate(
          (w) => w is VSearchBar && w.hintText == 'Tìm sản phẩm, SKU hoặc lô',
        ),
        findsOneWidget,
      );

      // Check Section "Việc của bạn"
      expect(find.text('Việc của bạn'), findsOneWidget);
      expect(find.text('3 việc'), findsOneWidget);

      // Check Tasks
      expect(find.text('PN-260816-04'), findsOneWidget);
      expect(find.text('Minh Dũng · 2 dòng hàng'), findsOneWidget);
      expect(find.text('Cần nhận'), findsOneWidget);

      expect(find.text('SO-260827-21'), findsOneWidget);
      expect(find.text('Đại lý An Phú · 2 sản phẩm'), findsOneWidget);
      expect(find.text('Đang lấy'), findsOneWidget);

      expect(find.text('KK-0709-03'), findsOneWidget);
      expect(find.text('Kho trung tâm · 12/38 đã đếm'), findsOneWidget);
      expect(find.text('Đang đếm'), findsOneWidget);

      // Check "Bắt đầu việc mới"
      expect(find.text('Bắt đầu việc mới'), findsOneWidget);
      expect(
        find.text('Nhập hàng nhanh, kiểm kê, đổi tình trạng hoặc tiêu hủy'),
        findsOneWidget,
      );

      // Check Section "Tra cứu"
      expect(find.text('Tra cứu'), findsOneWidget);
      expect(find.text('Tồn kho'), findsOneWidget);
      expect(find.text('Tra cứu số lượng, lô và khả dụng'), findsOneWidget);
      expect(find.text('Báo cáo & thẻ kho'), findsOneWidget);
      expect(find.text('Xem tồn tại thời điểm và lịch sử biến động'), findsOneWidget);
      expect(find.text('Tất cả chức năng kho'), findsOneWidget);
      expect(find.text('Xem các chức năng và thiết lập khác'), findsOneWidget);
    });

    testWidgets('tapping Bắt đầu việc mới opens the bottom sheet with 4 actions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = WarehouseHomeCubit(repository: const InventoryRepository());
      await cubit.load();
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: WarehouseHomePage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on "Bắt đầu việc mới"
      await tester.tap(find.text('Bắt đầu việc mới'));
      await tester.pumpAndSettle();

      // Verify bottom sheet is shown
      expect(find.byType(WarehouseStartNewSheet), findsOneWidget);
      expect(find.text('Nhập hàng nhanh'), findsOneWidget);
      expect(find.text('Hàng đã đến nhưng chưa có chứng từ mua'), findsOneWidget);
      expect(find.text('Tạo phiên kiểm kê'), findsOneWidget);
      expect(find.text('Chuyển tình trạng hàng'), findsOneWidget);
      expect(find.text('Tạo yêu cầu tiêu hủy'), findsOneWidget);
    });

    testWidgets('searching filters tasks accordingly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = WarehouseHomeCubit(repository: const InventoryRepository());
      await cubit.load();
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: WarehouseHomePage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search text "PN" into the TextField inside VSearchBar
      await tester.enterText(find.byType(TextField), 'PN');
      await tester.pumpAndSettle();

      // Should show PN-260816-04 but not SO-260827-21 or KK-0709-03
      expect(find.text('PN-260816-04'), findsOneWidget);
      expect(find.text('SO-260827-21'), findsNothing);
      expect(find.text('KK-0709-03'), findsNothing);
      expect(find.text('1 việc'), findsOneWidget);
    });

    testWidgets('B8: chạm task chưa có màn hình chỉ hiện toast', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = WarehouseHomeCubit(repository: const InventoryRepository());
      await cubit.load();
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: WarehouseHomePage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('SO-260827-21'));
      await tester.pump();

      // Không điều hướng: vẫn ở màn Kho, toast lặp lại phụ đề của task.
      expect(find.text('Việc của bạn'), findsOneWidget);
      expect(find.text('Đại lý An Phú · 2 sản phẩm'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
