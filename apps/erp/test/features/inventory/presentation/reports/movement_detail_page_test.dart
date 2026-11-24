import 'package:erp/features/inventory/data/reports/reports_models.dart';
import 'package:erp/features/inventory/data/reports/reports_repository.dart';
import 'package:erp/features/inventory/presentation/reports/movement_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'reports_test_support.dart';

void main() {
  late FakeReportsRepository repo;

  setUp(() async {
    await GetIt.I.reset();
    repo = FakeReportsRepository()..movementResult = movementDetailOf();
    GetIt.I.registerSingleton<ReportsRepository>(repo);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Widget page({Size size = const Size(390, 844), ValueChanged<String>? onOpen}) {
    return reportsApp(
      MovementDetailPage(
        movementId: 'm1',
        onOpenSource: onOpen ?? (_) {},
        onBack: () {},
      ),
      size: size,
    );
  }

  group('MovementDetailPage', () {
    testWidgets('movement_ready_390', (tester) async {
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      expect(find.text('Nhận hàng PN-260904-08'), findsOneWidget);
      expect(find.text('Vắc xin Dại'), findsOneWidget);
      expect(find.text('Trước'), findsOneWidget);
      expect(find.text('28 hộp'), findsOneWidget);
      expect(find.text('Biến động'), findsOneWidget);
      expect(find.text('+20 hộp'), findsOneWidget);
      expect(find.text('Sau'), findsOneWidget);
      expect(find.text('48 hộp'), findsAtLeastNWidgets(1));
      expect(find.text('Ngày nghiệp vụ'), findsOneWidget);
      expect(find.text('04/09/2026'), findsOneWidget);
      expect(find.text('Ngày ghi nhận'), findsOneWidget);
      expect(find.text('04/09/2026 · 08:15'), findsAtLeastNWidgets(1));
      expect(find.text('Người thực hiện'), findsOneWidget);
      expect(find.text('Giá trị'), findsOneWidget);
      expect(find.text('Tác động'), findsOneWidget);
      expect(find.text('+840.000 đ'), findsOneWidget);
      // Nguồn: 3 dòng
      expect(find.text('Nguồn'), findsOneWidget);
      expect(find.text('Giao dịch nguồn được hoàn tất'), findsOneWidget);
      expect(find.text('Đã ghi nhận kho'), findsOneWidget);
      expect(find.text('Tồn tăng 20 hộp'), findsOneWidget);
      expect(find.text('Số dư sau biến động: 48 hộp'), findsOneWidget);
      expect(find.text('Mở phiếu gốc'), findsOneWidget);
    });

    testWidgets('movement_ready_1280 puts Nguồn beside the facts', (tester) async {
      await tester.pumpWidget(page(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      final facts = tester.getTopLeft(find.text('Số lượng'));
      final source = tester.getTopLeft(find.text('Nguồn'));
      expect(source.dx, greaterThan(facts.dx + 200));
      expect((source.dy - facts.dy).abs(), lessThan(24));
    });

    testWidgets('movement_lot_row_when_lot_tracked', (tester) async {
      repo.movementResult = movementDetailOf(lot: 'A', lotTracked: true);
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      expect(find.text('Vắc xin Dại · Lô A'), findsOneWidget);
      expect(find.text('Lô'), findsOneWidget);
    });

    testWidgets('movement_staff_no_value', (tester) async {
      repo.movementResult = movementDetailOf(value: null);
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      expect(find.text('Giá trị'), findsNothing);
      expect(find.text('Tác động'), findsNothing);
      expect(findMoneyText(), findsNothing);
    });

    testWidgets('movement_receipt_opens_receipt', (tester) async {
      String? route;
      await tester.pumpWidget(page(onOpen: (r) => route = r));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mở phiếu gốc'));
      await tester.pumpAndSettle();
      expect(route, '/warehouse/receipts/r1');
    });

    testWidgets('movement_cancellation_opens_order', (tester) async {
      repo.movementResult = movementDetailOf(
        kind: 'SALE_REVERSAL',
        intent: 'SALES_CANCELLATION',
        delta: 3,
        source: const MovementSource(
          kind: 'CANCELLATION',
          docCode: 'DH-0001',
          orderId: 'o1',
        ),
      );
      String? route;
      await tester.pumpWidget(page(onOpen: (r) => route = r));
      await tester.pumpAndSettle();

      expect(find.text('Huỷ đơn DH-0001'), findsOneWidget);
      await tester.tap(find.text('Mở phiếu gốc'));
      await tester.pumpAndSettle();
      expect(route, '/sales/orders/o1');
    });

    testWidgets('movement_return_opens_return_detail', (tester) async {
      repo.movementResult = movementDetailOf(
        kind: 'RETURN_IN',
        intent: 'RETURN_EXCHANGE',
        delta: 1,
        source: const MovementSource(
          kind: 'RETURN_EXCHANGE',
          docCode: 'DH-0002',
          orderId: 'o2',
          returnId: 'x1',
        ),
      );
      String? route;
      await tester.pumpWidget(page(onOpen: (r) => route = r));
      await tester.pumpAndSettle();

      expect(find.text('Trả hàng DH-0002'), findsOneWidget);
      await tester.tap(find.text('Mở phiếu gốc'));
      await tester.pumpAndSettle();
      expect(route, '/sales/orders/o2/returns/x1/detail');
    });

    testWidgets('movement_stocktake_no_source_button', (tester) async {
      repo.movementResult = movementDetailOf(
        kind: 'COUNT_LOSS',
        intent: 'STOCKTAKE',
        reason: 'COUNT',
        delta: -1,
        value: -100000,
        source: const MovementSource(kind: 'STOCKTAKE', docCode: 'KK-REP-01'),
      );
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      expect(find.text('Kiểm kê thiếu KK-REP-01'), findsOneWidget);
      expect(find.text('Mở phiếu gốc'), findsNothing);
      expect(find.text('Tồn giảm 1 hộp'), findsOneWidget);
    });

    testWidgets('movement_zero_delta_copy', (tester) async {
      repo.movementResult = movementDetailOf(delta: 0, value: null);
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      expect(find.text('Tồn không đổi'), findsOneWidget);
      expect(find.text('0 hộp'), findsOneWidget);
    });
  });
}
