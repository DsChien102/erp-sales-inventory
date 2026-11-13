import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_repository.dart';
import 'package:erp/features/inventory/data/hub/warehouse_hub_repository.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_detail_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_header_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_line_editor_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_lines_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_list_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_result_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_review_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/widgets/receipt_product_search.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/widgets/receipt_supplier_field.dart';
import 'package:erp/features/inventory/presentation/patterns/expiry_date_field.dart';

import '../../support/inventory_router_harness.dart';

class _InactiveInventoryRpc extends Fake implements InventoryRpc {
  @override
  Future<Map<String, dynamic>> query(
    String fn, [
    Map<String, dynamic> params = const {},
  ]) async =>
      {'activated': false, 'problems': null};
}

class _FlowTestReceiptRepo extends Fake implements GoodsReceiptRepository {
  final List<Map<String, dynamic>> recordedPayloads = [];

  final options = const ReceiptFormOptions(
    warehouseName: 'Kho chính',
    today: '2026-11-10',
    suppliers: [
      ReceiptSupplierOption(
        id: 's-achau',
        name: 'Công ty Á Châu',
        code: 'AC',
        isSystem: false,
      ),
    ],
    products: [
      ReceiptProductOption(
        id: 'p-nobivac',
        name: 'Nobivac DHPPi',
        code: 'NOB-1',
        barcode: '8938500001012',
        baseUom: 'hộp',
        isLotTracked: true,
        expiryRequired: true,
        units: [ReceiptUnitOption(id: 'u-nob-hop', name: 'hộp', rate: 1, isBase: true)],
      ),
      ReceiptProductOption(
        id: 'p-giun',
        name: 'Thuốc tẩy giun',
        code: 'GIUN-1',
        barcode: '8938500002022',
        baseUom: 'gói',
        isLotTracked: true,
        expiryRequired: true,
        units: [ReceiptUnitOption(id: 'u-giun-goi', name: 'gói', rate: 1, isBase: true)],
      ),
    ],
    lots: [],
  );

  @override
  Future<List<ReceiptListRow>> list({String? supplierId, int limit = 100}) async => [
        ReceiptListRow(
          receiptId: 'rc-101',
          receiptNo: 'PN-261110-01',
          supplierId: 's-achau',
          supplierName: 'Công ty Á Châu',
          supplierIsSystem: false,
          supplierDocNo: 'HĐ 01',
          businessDate: '2026-11-10',
          lineCount: 2,
          lotCount: 2,
          landedTotalVnd: 30530000,
          createdByName: 'Kho chính',
          createdAt: '2026-11-10T10:00:00Z',
        ),
      ];

  @override
  Future<ReceiptFormOptions> formOptions() async => options;

  @override
  Future<RecordReceiptResult> record({
    required String idempotencyKey,
    required Map<String, dynamic> payload,
  }) async {
    recordedPayloads.add(payload);
    return RecordReceiptResult(
      receiptId: 'rc-101',
      receiptNo: 'PN-261110-01',
      businessDate: '2026-11-10',
      supplierName: 'Công ty Á Châu',
      supplierDocNo: payload['supplier_doc_no'] as String?,
      lineCount: (payload['lines'] as List).length,
      lotCount: 2,
      landedTotalVnd: 30530000,
      createdByName: 'Kho chính',
      stockChanges: const [
        K4StockChangeData(productName: 'Nobivac DHPPi', baseUom: 'hộp', before: 0, after: 300),
        K4StockChangeData(productName: 'Thuốc tẩy giun', baseUom: 'gói', before: 0, after: 11),
      ],
      reachedPrograms: const [
        ReceiptReachedProgram(programId: 'prog-rebate', name: 'Thưởng quý Q4'),
      ],
    );
  }

  @override
  Future<ReceiptDetail> get(String receiptId) async => ReceiptDetail(
        header: const ReceiptHeader(
          receiptId: 'rc-101',
          receiptNo: 'PN-261110-01',
          supplierId: 's-achau',
          supplierName: 'Công ty Á Châu',
          supplierIsSystem: false,
          businessDate: '2026-11-10',
          warehouseName: 'Kho chính',
          supplierDocNo: 'HĐ 01',
          freightCostVnd: 50000,
          tradeDiscountVnd: 20000,
          purchaseTotalVnd: 30500000,
          landedTotalVnd: 30530000,
          lineCount: 2,
          lotCount: 2,
          createdByName: 'Kho chính',
          createdAt: '2026-11-10T10:00:00Z',
        ),
        lines: const [
          ReceiptDetailLine(
            lineId: 'line-1',
            lineNo: 1,
            productId: 'p-nobivac',
            productName: 'Nobivac DHPPi',
            productCode: 'NOB-1',
            baseUom: 'hộp',
            unitName: 'hộp',
            conversionRate: 1,
            paidQty: 300,
            freeQty: 0,
            unitPriceVnd: 100000,
            tierDiscountPercent: 5,
            tierDiscountVnd: 1500000,
            grossAmountVnd: 30000000,
            purchaseAmountVnd: 28500000,
            allocatedFreightVnd: 49138,
            allocatedDiscountVnd: 19655,
            landedAmountVnd: 28529483,
            landedUnitCost: 95098.2767,
            programId: 'prog-tier',
            programName: 'Chiết khấu bậc Nobivac',
            lots: [
              ReceiptDetailLot(
                lotCode: 'DH1',
                expiryDate: '2026-11-30',
                manufactureDate: null,
                quantity: 300,
                allocatedLandedCostVnd: 28529483,
              ),
            ],
          ),
          ReceiptDetailLine(
            lineId: 'line-2',
            lineNo: 2,
            productId: 'p-giun',
            productName: 'Thuốc tẩy giun',
            productCode: 'GIUN-1',
            baseUom: 'gói',
            unitName: 'gói',
            conversionRate: 1,
            paidQty: 10,
            freeQty: 1,
            unitPriceVnd: 50000,
            tierDiscountPercent: null,
            tierDiscountVnd: 0,
            grossAmountVnd: 500000,
            purchaseAmountVnd: 500000,
            allocatedFreightVnd: 862,
            allocatedDiscountVnd: 345,
            landedAmountVnd: 500517,
            landedUnitCost: 45501.5455,
            programId: 'prog-bxy',
            programName: 'Mua 10 tặng 1',
            lots: [
              ReceiptDetailLot(
                lotCode: 'TG1',
                expiryDate: '2027-11-30',
                manufactureDate: null,
                quantity: 11,
                allocatedLandedCostVnd: 500517,
              ),
            ],
          ),
        ],
      );
}

class _FlowTestProgramRepo extends Fake implements SupplierProgramRepository {
  @override
  Future<List<ProgramHint?>> receiptHints({
    required String supplierId,
    required List<({String productId, num paidQty, int unitPrice})> lines,
  }) async {
    return lines.map<ProgramHint?>((l) {
      if (l.productId == 'p-nobivac') {
        if (l.paidQty >= 300) {
          return const ProgramHint(
            programId: 'prog-tier',
            programName: 'Chiết khấu bậc Nobivac',
            kind: ProgramKind.tierDiscount,
            tier: (minQty: 300, percent: 5.0, discountVnd: 1500000),
          );
        } else if (l.paidQty >= 100) {
          return const ProgramHint(
            programId: 'prog-tier',
            programName: 'Chiết khấu bậc Nobivac',
            kind: ProgramKind.tierDiscount,
            tier: (minQty: 100, percent: 3.0, discountVnd: 300000),
          );
        }
      } else if (l.productId == 'p-giun') {
        if (l.paidQty >= 10) {
          return const ProgramHint(
            programId: 'prog-bxy',
            programName: 'Mua 10 tặng 1',
            kind: ProgramKind.buyXGetY,
            buyQty: 10,
            freeQty: 1,
            suggestedFreeQty: 1,
          );
        }
      }
      return null;
    }).toList();
  }
}

void main() {
  late _FlowTestReceiptRepo receiptRepo;
  late _FlowTestProgramRepo programRepo;

  setUp(() async {
    await setUpInventoryRouterTest();
    receiptRepo = _FlowTestReceiptRepo();
    programRepo = _FlowTestProgramRepo();

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

  group('Goods Receipt Flow E2E Tests (Task 7)', () {
    testWidgets('receive_flow_end_to_end_390', (tester) async {
      // 1. Khởi đầu từ Hub kho trống: Banner "Lập phiếu nhận"
      getIt.unregister<WarehouseHubRepository>();
      getIt.registerSingleton<WarehouseHubRepository>(
        WarehouseHubRepository(rpc: _InactiveInventoryRpc()),
      );

      await pumpInventoryApp(
        tester,
        size: const Size(390, 844),
        location: '/warehouse',
      );

      final bannerBtn = find.widgetWithText(VButton, 'Lập phiếu nhận');
      expect(bannerBtn, findsOneWidget);
      await tester.tap(bannerBtn);
      await tester.pumpAndSettle();

      // Mở ReceiptListPage (màn 007)
      expect(find.byType(ReceiptListPage), findsOneWidget);

      // Bấm "Nhận hàng" để vào tạo phiếu mới
      final newReceiptBtn = find.widgetWithText(VButton, 'Nhận hàng');
      expect(newReceiptBtn, findsOneWidget);
      await tester.tap(newReceiptBtn);
      await tester.pumpAndSettle();

      // Màn 008: ReceiptHeaderPage
      expect(find.byType(ReceiptHeaderPage), findsOneWidget);

      // Chọn NCC Á Châu
      await tester.tap(find.byType(ReceiptSupplierField));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Công ty Á Châu'));
      await tester.pumpAndSettle();

      // Nhập số chứng từ "HĐ 01"
      final docField = find.byKey(const Key('receipt_doc_no'));
      await tester.enterText(docField, 'HĐ 01');
      await tester.pumpAndSettle();

      // Bấm Tiếp tục -> sang 009 ReceiptLinesPage
      await tester.tap(find.widgetWithText(VButton, 'Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.byType(ReceiptLinesPage), findsOneWidget);

      // 2. Thêm dòng 1: Nobivac DHPPi
      await tester.tap(find.byType(ReceiptProductSearch));
      await tester.pumpAndSettle();

      // Tìm và chọn Nobivac DHPPi trong search sheet
      await tester.tap(find.text('Nobivac DHPPi'));
      await tester.pumpAndSettle();

      // Đã mở ReceiptLineEditorPage (màn 084)
      expect(find.byType(ReceiptLineEditorPage), findsOneWidget);

      // Nhập mã lô: DH1
      final lotCodeField = find.byKey(const Key('receipt_lot_code'));
      await tester.enterText(lotCodeField, 'DH1');
      await tester.pumpAndSettle();

      // Nhập HSD: 30/11/2026
      final expiryField = find.descendant(
        of: find.byType(InventoryExpiryField),
        matching: find.byType(VTextField),
      );
      await tester.enterText(expiryField, '30/11/2026');
      await tester.pumpAndSettle();

      // Nhập SL: 300
      final qtyField = find.byKey(const Key('receipt_lot_qty'));
      await tester.ensureVisible(qtyField);
      await tester.enterText(qtyField, '300');
      await tester.pumpAndSettle();

      // Nhập Giá mua: 100000
      final priceField = find.byKey(const Key('receipt_unit_price'));
      await tester.ensureVisible(priceField);
      await tester.enterText(priceField, '100000');
      await tester.pumpAndSettle();

      // Chờ debounce hint 500ms
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Kiểm tra % giảm theo bậc đã tự điền 5
      expect(find.text('% giảm theo bậc'), findsOneWidget);

      // Bấm Xong -> quay lại 009
      final doneBtn1 = find.widgetWithText(VButton, 'Xong');
      await tester.ensureVisible(doneBtn1);
      await tester.tap(doneBtn1);
      await tester.pumpAndSettle();
      expect(find.byType(ReceiptLinesPage), findsOneWidget);

      // 3. Thêm dòng 2: Thuốc tẩy giun
      await tester.tap(find.byType(ReceiptProductSearch));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thuốc tẩy giun'));
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptLineEditorPage), findsOneWidget);

      // Nhập mã lô: TG1
      final lotCodeField2 = find.byKey(const Key('receipt_lot_code'));
      await tester.enterText(lotCodeField2, 'TG1');
      await tester.pumpAndSettle();

      // Nhập HSD: 11/2027
      final expiryField2 = find.descendant(
        of: find.byType(InventoryExpiryField),
        matching: find.byType(VTextField),
      );
      await tester.enterText(expiryField2, '11/2027');
      await tester.pumpAndSettle();

      // Nhập SL: 11
      final qtyField2 = find.byKey(const Key('receipt_lot_qty'));
      await tester.ensureVisible(qtyField2);
      await tester.enterText(qtyField2, '11');
      await tester.pumpAndSettle();

      // Nhập Giá mua: 50000
      final priceField2 = find.byKey(const Key('receipt_unit_price'));
      await tester.ensureVisible(priceField2);
      await tester.enterText(priceField2, '50000');
      await tester.pumpAndSettle();

      // Chờ debounce hint 500ms
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Kiểm tra ô SL tặng đã tự điền 1
      expect(find.text('SL tặng'), findsOneWidget);

      // Bấm Xong -> quay lại 009
      final doneBtn2 = find.widgetWithText(VButton, 'Xong');
      await tester.ensureVisible(doneBtn2);
      await tester.tap(doneBtn2);
      await tester.pumpAndSettle();
      expect(find.byType(ReceiptLinesPage), findsOneWidget);

      // 4. Màn 009: 2 dòng đã xong -> Bấm "Tiếp tục" sang màn 010 Rà soát
      final continueBtn = find.widgetWithText(VButton, 'Tiếp tục');
      expect(continueBtn, findsOneWidget);
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Màn 010: ReceiptReviewPage
      expect(find.byType(ReceiptReviewPage), findsOneWidget);

      // Nhập Chi phí thu mua: 50.000, Chiết khấu thương mại: 20.000
      final freightField = find.byKey(const Key('receipt_freight_cost'));
      await tester.ensureVisible(freightField);
      await tester.enterText(freightField, '50000');
      await tester.pumpAndSettle();

      final discountField = find.byKey(const Key('receipt_trade_discount'));
      await tester.ensureVisible(discountField);
      await tester.enterText(discountField, '20000');
      await tester.pumpAndSettle();

      // Bấm "Ghi nhận"
      final submitBtn = find.widgetWithText(VButton, 'Ghi nhận');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // 5. Kiểm tra payload đã gửi
      expect(receiptRepo.recordedPayloads, hasLength(1));
      final payload = receiptRepo.recordedPayloads.first;
      expect(payload['supplier_id'], 's-achau');
      expect(payload['supplier_doc_no'], 'HĐ 01');
      expect(payload['freight_cost_vnd'], 50000);
      expect(payload['trade_discount_vnd'], 20000);

      final lines = payload['lines'] as List;
      expect(lines, hasLength(2));

      final line1 = lines.firstWhere((l) => l['product_id'] == 'p-nobivac');
      expect(line1['unit_price_vnd'], 100000);
      expect(line1['tier_discount_percent'], 5.0);
      expect(line1['program_id'], 'prog-tier');
      expect(line1['lots'], hasLength(1));
      expect(line1['lots'][0]['lot_code'], 'DH1');
      expect(line1['lots'][0]['quantity'], 300);

      final line2 = lines.firstWhere((l) => l['product_id'] == 'p-giun');
      expect(line2['unit_price_vnd'], 50000);
      expect(line2['free_qty'], 1);
      expect(line2['program_id'], 'prog-bxy');
      expect(line2['lots'], hasLength(1));
      expect(line2['lots'][0]['lot_code'], 'TG1');
      expect(line2['lots'][0]['quantity'], 11);

      // 6. Màn 012: ReceiptResultPage
      expect(find.byType(ReceiptResultPage), findsOneWidget);
      expect(find.text('Ghi nhận hàng thành công'), findsOneWidget);
      expect(find.text('Thưởng quý Q4'), findsOneWidget);

      // Bấm "Xem phiếu PN-261110-01" -> mở màn xem lại ReceiptDetailPage
      final seeDetailBtn = find.widgetWithText(VButton, 'Xem phiếu PN-261110-01');
      expect(seeDetailBtn, findsOneWidget);
      await tester.ensureVisible(seeDetailBtn);
      await tester.tap(seeDetailBtn);
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptDetailPage), findsOneWidget);
      expect(find.text('PN-261110-01'), findsWidgets);
    });

    testWidgets('receive_flow_web_1280', (tester) async {
      // Bắt đầu từ /warehouse/receipts trên màn desktop
      await pumpInventoryApp(
        tester,
        size: const Size(1280, 800),
        location: '/warehouse/receipts',
      );

      expect(find.byType(ReceiptListPage), findsOneWidget);

      // Bấm "Nhận hàng" -> mở 008
      final newBtn = find.widgetWithText(VButton, 'Nhận hàng');
      expect(newBtn, findsOneWidget);
      await tester.tap(newBtn);
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptHeaderPage), findsOneWidget);

      // Chọn NCC Á Châu
      await tester.tap(find.byType(ReceiptSupplierField));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Công ty Á Châu'));
      await tester.pumpAndSettle();

      // Nhập số chứng từ "HĐ 01"
      final docField = find.byKey(const Key('receipt_doc_no'));
      await tester.enterText(docField, 'HĐ 01');
      await tester.pumpAndSettle();

      // Tiếp tục sang 009 (trên web là split editor)
      await tester.tap(find.widgetWithText(VButton, 'Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.byType(ReceiptLinesPage), findsOneWidget);

      // Thêm Nobivac DHPPi
      await tester.tap(find.byType(ReceiptProductSearch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nobivac DHPPi'));
      await tester.pumpAndSettle();

      // Trên Web split editor: Cột phải hiển thị editor ngay lập tức
      expect(find.text('Chi tiết hàng thực nhận'), findsOneWidget);

      // Nhập mã lô: DH1
      final lotCodeField = find.byKey(const Key('receipt_lot_code'));
      await tester.enterText(lotCodeField, 'DH1');
      await tester.pumpAndSettle();

      // Nhập HSD: 30/11/2026
      final expiryField = find.descendant(
        of: find.byType(InventoryExpiryField),
        matching: find.byType(VTextField),
      );
      await tester.enterText(expiryField, '30/11/2026');
      await tester.pumpAndSettle();

      // Nhập SL: 300, Giá: 100.000
      final qtyField = find.byKey(const Key('receipt_lot_qty'));
      await tester.ensureVisible(qtyField);
      await tester.enterText(qtyField, '300');
      await tester.pumpAndSettle();

      final priceField = find.byKey(const Key('receipt_unit_price'));
      await tester.ensureVisible(priceField);
      await tester.enterText(priceField, '100000');
      await tester.pumpAndSettle();

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Bấm Xong trên editor
      final doneBtn1 = find.widgetWithText(VButton, 'Xong');
      await tester.ensureVisible(doneBtn1);
      await tester.tap(doneBtn1);
      await tester.pumpAndSettle();

      // Thêm Thuốc tẩy giun
      await tester.tap(find.byType(ReceiptProductSearch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thuốc tẩy giun'));
      await tester.pumpAndSettle();

      final lotCodeField2 = find.byKey(const Key('receipt_lot_code'));
      await tester.enterText(lotCodeField2, 'TG1');
      await tester.pumpAndSettle();

      final expiryField2 = find.descendant(
        of: find.byType(InventoryExpiryField),
        matching: find.byType(VTextField),
      );
      await tester.enterText(expiryField2, '11/2027');
      await tester.pumpAndSettle();

      final qtyField2 = find.byKey(const Key('receipt_lot_qty'));
      await tester.ensureVisible(qtyField2);
      await tester.enterText(qtyField2, '11');
      await tester.pumpAndSettle();

      final priceField2 = find.byKey(const Key('receipt_unit_price'));
      await tester.ensureVisible(priceField2);
      await tester.enterText(priceField2, '50000');
      await tester.pumpAndSettle();

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final doneBtn2 = find.widgetWithText(VButton, 'Xong');
      await tester.ensureVisible(doneBtn2);
      await tester.tap(doneBtn2);
      await tester.pumpAndSettle();

      // Bấm "Tiếp tục" sang 010
      final continueBtn = find.widgetWithText(VButton, 'Tiếp tục');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptReviewPage), findsOneWidget);

      // Điền Chi phí & Chiết khấu
      final freightField = find.byKey(const Key('receipt_freight_cost'));
      await tester.ensureVisible(freightField);
      await tester.enterText(freightField, '50000');
      await tester.pumpAndSettle();

      final discountField = find.byKey(const Key('receipt_trade_discount'));
      await tester.ensureVisible(discountField);
      await tester.enterText(discountField, '20000');
      await tester.pumpAndSettle();

      // Ghi nhận
      final submitBtn = find.widgetWithText(VButton, 'Ghi nhận');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptResultPage), findsOneWidget);

      // Bấm "Xem phiếu PN-261110-01"
      final seeDetailBtn = find.widgetWithText(VButton, 'Xem phiếu PN-261110-01');
      await tester.tap(seeDetailBtn);
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptDetailPage), findsOneWidget);
    });
  });
}
