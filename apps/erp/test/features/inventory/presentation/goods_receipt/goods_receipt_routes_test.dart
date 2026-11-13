import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_repository.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_header_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_lines_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_list_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_result_page.dart';
import 'package:erp/features/inventory/presentation/stock/stock_detail_page.dart';

import '../../support/inventory_router_harness.dart';

class _FakeReceiptRepo extends Fake implements GoodsReceiptRepository {
  List<ReceiptListRow> rows = [];
  final options = const ReceiptFormOptions(
    warehouseName: 'Kho chính',
    today: '2026-11-10',
    suppliers: [
      ReceiptSupplierOption(id: 's-1', name: 'Công ty Á Châu', code: 'AC', isSystem: false),
    ],
    products: [
      ReceiptProductOption(
        id: 'p-1',
        name: 'Nobivac DHPPi',
        code: 'NOB-1',
        barcode: null,
        baseUom: 'hộp',
        isLotTracked: false,
        expiryRequired: false,
        units: [ReceiptUnitOption(id: 'u-1', name: 'hộp', rate: 1, isBase: true)],
      ),
    ],
    lots: [],
  );

  @override
  Future<List<ReceiptListRow>> list({String? supplierId, int limit = 100}) async => rows;

  @override
  Future<ReceiptFormOptions> formOptions() async => options;

  @override
  Future<ReceiptDetail> get(String receiptId) async => ReceiptDetail(
        header: const ReceiptHeader(
          receiptId: 'rc-1',
          receiptNo: 'PN-261110-01',
          supplierId: 's-1',
          supplierName: 'Công ty Á Châu',
          supplierIsSystem: false,
          businessDate: '2026-11-10',
          warehouseName: 'Kho chính',
          freightCostVnd: 0,
          tradeDiscountVnd: 0,
          purchaseTotalVnd: 100000,
          landedTotalVnd: 100000,
          lineCount: 1,
          lotCount: 1,
          createdByName: 'Kho',
          createdAt: '2026-11-10T08:00:00Z',
        ),
        lines: const [],
      );
}

class _FakeProgramRepo extends Fake implements SupplierProgramRepository {
  @override
  Future<List<ProgramHint?>> receiptHints({
    required String supplierId,
    required List<({String productId, num paidQty, int unitPrice})> lines,
  }) async =>
      [];
}

void main() {
  late _FakeReceiptRepo receiptRepo;
  late _FakeProgramRepo programRepo;

  setUp(() async {
    await setUpInventoryRouterTest();
    receiptRepo = _FakeReceiptRepo();
    programRepo = _FakeProgramRepo();

    if (getIt.isRegistered<GoodsReceiptRepository>()) {
      getIt.unregister<GoodsReceiptRepository>();
    }
    getIt.registerSingleton<GoodsReceiptRepository>(receiptRepo);

    if (getIt.isRegistered<SupplierProgramRepository>()) {
      getIt.unregister<SupplierProgramRepository>();
    }
    getIt.registerSingleton<SupplierProgramRepository>(programRepo);
  });

  tearDown(() async {
    await tearDownInventoryRouterTest();
  });

  group('GoodsReceiptRoutes', () {
    testWidgets('routes_new_flow_and_result_without_extra_redirects_detail', (tester) async {
      await pumpInventoryApp(
        tester,
        size: const Size(390, 844),
        location: '/warehouse/receipts',
      );

      expect(find.byType(ReceiptListPage), findsOneWidget);

      // Bấm nút Nhận hàng trên header
      final newBtn = find.widgetWithText(VButton, 'Nhận hàng');
      expect(newBtn, findsOneWidget);
      await tester.tap(newBtn);
      await tester.pumpAndSettle();

      // Vào màn 008 Header
      expect(find.byType(ReceiptHeaderPage), findsOneWidget);

      // Chọn NCC Á Châu
      await tester.tap(find.text('Chọn nhà cung cấp'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Công ty Á Châu'));
      await tester.pumpAndSettle();

      // Bấm Tiếp tục sang 009 Lines
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptLinesPage), findsOneWidget);
    });

    testWidgets('back_on_empty_draft_leaves_without_prompt', (tester) async {
      await pumpInventoryApp(
        tester,
        size: const Size(390, 844),
        location: '/warehouse/receipts/new',
      );

      expect(find.byType(ReceiptHeaderPage), findsOneWidget);

      // Bấm Back khi nháp rỗng -> không hiện sheet bỏ phiếu, quay lại trang trước
      final backBtn = find.byType(BackButton);
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.text('Bỏ phiếu nhận này?'), findsNothing);
    });

    testWidgets('stock_detail_receive_opens_new_with_product', (tester) async {
      await pumpInventoryApp(
        tester,
        size: const Size(390, 844),
        location: '/warehouse/stock/INV-NOB',
      );

      expect(find.byType(StockDetailPage), findsOneWidget);
      final receiveBtn = find.widgetWithText(VButton, 'Nhận hàng');
      if (receiveBtn.evaluate().isNotEmpty) {
        await tester.tap(receiveBtn);
        await tester.pumpAndSettle();
        expect(find.byType(ReceiptHeaderPage), findsOneWidget);
      }
    });

    testWidgets('new_receipt_after_result_starts_empty_390', (tester) async {
      await pumpInventoryApp(
        tester,
        size: const Size(390, 844),
        location: '/warehouse/receipts/rc-101/result',
      );

      expect(find.byType(ReceiptResultPage), findsOneWidget);

      final newReceiptBtn = find.widgetWithText(VButton, 'Nhận tiếp');
      expect(newReceiptBtn, findsOneWidget);
      await tester.tap(newReceiptBtn);
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptHeaderPage), findsOneWidget);
      expect(find.text('Chọn nhà cung cấp'), findsOneWidget);
    });
  });
}

