import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_repository.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_header_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_line_editor_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_lines_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_list_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_result_page.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_review_page.dart';
import 'package:erp/features/inventory/presentation/patterns/expiry_date_field.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/widgets/receipt_product_search.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/widgets/receipt_supplier_field.dart';

import '../../support/inventory_router_harness.dart';

String _screenshotPath(String fileName) {
  final root = Directory.current.path.endsWith('apps/erp')
      ? Directory.current.parent.parent.path
      : Directory.current.path;
  return '$root/docs/refactor/plans/T7/img/G5-3/$fileName';
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey key,
  String fileName,
) async {
  await tester.pumpAndSettle();
  final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return;
  // Chỉ ghi ảnh vào docs khi chủ động bật: CAPTURE_SCREENSHOTS=1 flutter test ...
  if (Platform.environment['CAPTURE_SCREENSHOTS'] != '1') return;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final file = File(_screenshotPath(fileName));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(byteData.buffer.asUint8List());
  });
}

class _GoldenFakeRepo extends Fake implements GoodsReceiptRepository {
  final options = const ReceiptFormOptions(
    warehouseName: 'Kho trung tâm',
    today: '2026-11-10',
    suppliers: [
      ReceiptSupplierOption(
        id: 's-minhdung',
        name: 'Minh Dũng',
        code: 'MD',
        isSystem: false,
      ),
    ],
    products: [
      ReceiptProductOption(
        id: 'p-nobivac',
        name: 'Nobivac DHPPi',
        code: 'SP-000184',
        barcode: null,
        baseUom: 'hộp',
        isLotTracked: true,
        expiryRequired: true,
        units: [ReceiptUnitOption(id: 'u-nob-hop', name: 'hộp', rate: 1, isBase: true)],
      ),
      ReceiptProductOption(
        id: 'p-oxytetra',
        name: 'Oxytetracycline LA',
        code: 'SP-000147',
        barcode: null,
        baseUom: 'chai',
        isLotTracked: false,
        expiryRequired: false,
        units: [ReceiptUnitOption(id: 'u-oxy-chai', name: 'chai', rate: 1, isBase: true)],
      ),
    ],
    lots: [],
  );

  @override
  Future<List<ReceiptListRow>> list({String? supplierId, int limit = 100}) async => [
        const ReceiptListRow(
          receiptId: 'rc-101',
          receiptNo: 'PN-261110-01',
          supplierId: 's-minhdung',
          supplierName: 'Minh Dũng',
          supplierIsSystem: false,
          supplierDocNo: 'HĐ 0001523',
          businessDate: '2026-11-10',
          lineCount: 2,
          lotCount: 1,
          landedTotalVnd: 4640000,
          createdByName: 'Nguyễn Văn Kho',
          createdAt: '2026-11-10T08:30:00Z',
        ),
      ];

  @override
  Future<ReceiptFormOptions> formOptions() async => options;

  @override
  Future<RecordReceiptResult> record({
    required String idempotencyKey,
    required Map<String, dynamic> payload,
  }) async =>
      const RecordReceiptResult(
        receiptId: 'rc-101',
        receiptNo: 'PN-261110-01',
        businessDate: '2026-11-10',
        supplierName: 'Minh Dũng',
        supplierDocNo: 'HĐ 0001523',
        lineCount: 2,
        lotCount: 1,
        landedTotalVnd: 4640000,
        createdByName: 'Nguyễn Văn Kho',
        stockChanges: [
          K4StockChangeData(productName: 'Nobivac DHPPi', baseUom: 'hộp', before: 100, after: 120),
          K4StockChangeData(productName: 'Oxytetracycline LA', baseUom: 'chai', before: 50, after: 74),
        ],
        reachedPrograms: [],
      );

  @override
  Future<ReceiptDetail> get(String receiptId) async => ReceiptDetail(
        header: const ReceiptHeader(
          receiptId: 'rc-101',
          receiptNo: 'PN-261110-01',
          supplierId: 's-minhdung',
          supplierName: 'Minh Dũng',
          supplierIsSystem: false,
          businessDate: '2026-11-10',
          warehouseName: 'Kho trung tâm',
          supplierDocNo: 'HĐ 0001523',
          freightCostVnd: 0,
          tradeDiscountVnd: 0,
          purchaseTotalVnd: 4640000,
          landedTotalVnd: 4640000,
          lineCount: 2,
          lotCount: 1,
          createdByName: 'Nguyễn Văn Kho',
          createdAt: '2026-11-10T08:30:00Z',
        ),
        lines: const [
          ReceiptDetailLine(
            lineId: 'l-1',
            lineNo: 1,
            productId: 'p-nobivac',
            productName: 'Nobivac DHPPi',
            productCode: 'SP-000184',
            baseUom: 'hộp',
            unitName: 'hộp',
            conversionRate: 1,
            paidQty: 20,
            freeQty: 0,
            unitPriceVnd: 118000,
            grossAmountVnd: 2360000,
            tierDiscountVnd: 0,
            purchaseAmountVnd: 2360000,
            allocatedFreightVnd: 0,
            allocatedDiscountVnd: 0,
            landedAmountVnd: 2360000,
            landedUnitCost: 118000,
            lots: [
              ReceiptDetailLot(
                lotCode: 'DH2507',
                expiryDate: '2026-11-30',
                manufactureDate: null,
                quantity: 20,
                allocatedLandedCostVnd: 2360000,
              ),
            ],
          ),
          ReceiptDetailLine(
            lineId: 'l-2',
            lineNo: 2,
            productId: 'p-oxytetra',
            productName: 'Oxytetracycline LA',
            productCode: 'SP-000147',
            baseUom: 'chai',
            unitName: 'chai',
            conversionRate: 1,
            paidQty: 24,
            freeQty: 0,
            unitPriceVnd: 95000,
            grossAmountVnd: 2280000,
            tierDiscountVnd: 0,
            purchaseAmountVnd: 2280000,
            allocatedFreightVnd: 0,
            allocatedDiscountVnd: 0,
            landedAmountVnd: 2280000,
            landedUnitCost: 95000,
            lots: [
              ReceiptDetailLot(
                lotCode: null,
                expiryDate: null,
                manufactureDate: null,
                quantity: 24,
                allocatedLandedCostVnd: 2280000,
              ),
            ],
          ),
        ],
      );
}

class _GoldenFakeProgramRepo extends Fake implements SupplierProgramRepository {
  @override
  Future<List<ProgramHint?>> receiptHints({
    required String supplierId,
    required List<({String productId, num paidQty, int unitPrice})> lines,
  }) async =>
      [];
}

void main() {
  setUp(() async {
    await setUpInventoryRouterTest();
    final repo = _GoldenFakeRepo();
    final programRepo = _GoldenFakeProgramRepo();

    if (getIt.isRegistered<GoodsReceiptRepository>()) {
      getIt.unregister<GoodsReceiptRepository>();
    }
    getIt.registerSingleton<GoodsReceiptRepository>(repo);

    if (getIt.isRegistered<SupplierProgramRepository>()) {
      getIt.unregister<SupplierProgramRepository>();
    }
    getIt.registerSingleton<SupplierProgramRepository>(programRepo);
  });

  tearDown(() async {
    await tearDownInventoryRouterTest();
  });

  group('Goods Receipt Golden Screenshots (Task 8)', () {
    testWidgets('capture_mobile_390_screens', (tester) async {
      // 1. SCR-007 Danh sách (390)
      final key007 = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(390, 844),
        location: '/warehouse/receipts',
        repaintBoundaryKey: key007,
      );
      expect(find.byType(ReceiptListPage), findsOneWidget);
      await _capture(tester, key007, 'flutter-SCR-007-READY-390.png');

      // 2. SCR-008 Thông tin nhận hàng (390)
      final key008 = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(390, 844),
        location: '/warehouse/receipts/new',
        repaintBoundaryKey: key008,
      );
      expect(find.byType(ReceiptHeaderPage), findsOneWidget);

      // Điền thông tin chuẩn prototype
      await tester.tap(find.byType(ReceiptSupplierField));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Minh Dũng').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('receipt_doc_no')),
        'HĐ 0001523',
      );
      await tester.pumpAndSettle();
      await _capture(tester, key008, 'flutter-SCR-008-READY-390.png');

      // Chuyển sang màn thêm hàng (SCR-009)
      final continueBtn = find.widgetWithText(VButton, 'Tiếp tục');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();
      expect(find.byType(ReceiptLinesPage), findsOneWidget);

      // Thêm dòng 1: Nobivac DHPPi
      await tester.tap(find.byType(ReceiptProductSearch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nobivac DHPPi').last);
      await tester.pumpAndSettle();

      // Đang ở màn 084 (Mobile mở thẳng ReceiptLineEditorPage)
      expect(find.byType(ReceiptLineEditorPage), findsOneWidget);

      final lotCodeField = find.byKey(const Key('receipt_lot_code'));
      await tester.enterText(lotCodeField, 'DH2507');
      await tester.pumpAndSettle();

      final expiryField = find.descendant(
        of: find.byType(InventoryExpiryField),
        matching: find.byType(VTextField),
      );
      await tester.enterText(expiryField, '30/11/2026');
      await tester.pumpAndSettle();

      final qtyField = find.byKey(const Key('receipt_lot_qty'));
      await tester.ensureVisible(qtyField);
      await tester.enterText(qtyField, '20');
      await tester.pumpAndSettle();

      final priceField = find.byKey(const Key('receipt_unit_price'));
      await tester.ensureVisible(priceField);
      await tester.enterText(priceField, '118000');
      await tester.pumpAndSettle();

      // SCR-084 Sửa dòng trên mobile (390)
      await _capture(tester, key008, 'flutter-SCR-084-READY-390.png');

      final doneBtn = find.widgetWithText(VButton, 'Xong');
      await tester.ensureVisible(doneBtn);
      await tester.tap(doneBtn);
      await tester.pumpAndSettle();
      expect(find.byType(ReceiptLinesPage), findsOneWidget);

      // Thêm dòng 2: Oxytetracycline LA
      await tester.tap(find.byType(ReceiptProductSearch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oxytetracycline LA').last);
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptLineEditorPage), findsOneWidget);
      final qtyField2 = find.byKey(const Key('receipt_untracked_qty'));
      await tester.ensureVisible(qtyField2);
      await tester.enterText(qtyField2, '24');
      await tester.pumpAndSettle();

      final priceField2 = find.byKey(const Key('receipt_unit_price'));
      await tester.ensureVisible(priceField2);
      await tester.enterText(priceField2, '95000');
      await tester.pumpAndSettle();

      final doneBtn2 = find.widgetWithText(VButton, 'Xong');
      await tester.ensureVisible(doneBtn2);
      await tester.tap(doneBtn2);
      await tester.pumpAndSettle();
      expect(find.byType(ReceiptLinesPage), findsOneWidget);

      // 3. SCR-009 Danh sách dòng nhận hàng (390)
      await _capture(tester, key008, 'flutter-SCR-009-READY-390.png');

      // 4. SCR-010 Xem lại & Xác nhận (390)
      final reviewBtn = find.widgetWithText(VButton, 'Tiếp tục');
      await tester.ensureVisible(reviewBtn);
      await tester.tap(reviewBtn);
      await tester.pumpAndSettle();
      expect(find.byType(ReceiptReviewPage), findsOneWidget);
      await _capture(tester, key008, 'flutter-SCR-010-READY-390.png');

      // 5. SCR-012 Kết quả (390)
      final submitBtn = find.widgetWithText(VButton, 'Ghi nhận');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.byType(ReceiptResultPage), findsOneWidget);
      await _capture(tester, key008, 'flutter-SCR-012-COMPLETED-390.png');
    });

    testWidgets('capture_desktop_1280_screens', (tester) async {
      // 1. SCR-007 Danh sách (1280)
      final key007 = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(1280, 800),
        location: '/warehouse/receipts',
        repaintBoundaryKey: key007,
      );
      expect(find.byType(ReceiptListPage), findsOneWidget);
      await _capture(tester, key007, 'flutter-SCR-007-READY-1280.png');

      // 2. SCR-008 Thông tin nhận hàng (1280)
      final key008 = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(1280, 800),
        location: '/warehouse/receipts/new',
        repaintBoundaryKey: key008,
      );
      expect(find.byType(ReceiptHeaderPage), findsOneWidget);

      await tester.tap(find.byType(ReceiptSupplierField));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Minh Dũng').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('receipt_doc_no')),
        'HĐ 0001523',
      );
      await tester.pumpAndSettle();
      await _capture(tester, key008, 'flutter-SCR-008-READY-1280.png');

      // Chuyển sang màn Thêm hàng (1280 - split pane)
      final continueBtn = find.widgetWithText(VButton, 'Tiếp tục');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();
      expect(find.byType(ReceiptLinesPage), findsOneWidget);

      // Thêm dòng 1: Nobivac DHPPi
      await tester.tap(find.byType(ReceiptProductSearch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nobivac DHPPi').last);
      await tester.pumpAndSettle();

      // Trên 1280, sau khi chọn sản phẩm nó nằm ở pane bên phải
      final lotCodeField = find.byKey(const Key('receipt_lot_code'));
      await tester.enterText(lotCodeField, 'DH2507');
      await tester.pumpAndSettle();

      final expiryField = find.descendant(
        of: find.byType(InventoryExpiryField),
        matching: find.byType(VTextField),
      );
      await tester.enterText(expiryField, '30/11/2026');
      await tester.pumpAndSettle();

      final qtyField = find.byKey(const Key('receipt_lot_qty'));
      await tester.ensureVisible(qtyField);
      await tester.enterText(qtyField, '20');
      await tester.pumpAndSettle();

      final priceField = find.byKey(const Key('receipt_unit_price'));
      await tester.ensureVisible(priceField);
      await tester.enterText(priceField, '118000');
      await tester.pumpAndSettle();

      // Thêm dòng 2: Oxytetracycline LA
      await tester.tap(find.byType(ReceiptProductSearch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oxytetracycline LA').last);
      await tester.pumpAndSettle();

      final qtyField2 = find.byKey(const Key('receipt_untracked_qty'));
      await tester.ensureVisible(qtyField2);
      await tester.enterText(qtyField2, '24');
      await tester.pumpAndSettle();

      final priceField2 = find.byKey(const Key('receipt_unit_price'));
      await tester.ensureVisible(priceField2);
      await tester.enterText(priceField2, '95000');
      await tester.pumpAndSettle();

      // Chọn lại dòng Nobivac để panel bên phải hiển thị chi tiết dòng 1 kèm lô
      await tester.tap(find.text('Nobivac DHPPi').first);
      await tester.pumpAndSettle();

      // 3. SCR-009 Split-pane (1280)
      await _capture(tester, key008, 'flutter-SCR-009-READY-1280.png');

      // 4. SCR-010 Xem lại (1280)
      final reviewBtn = find.widgetWithText(VButton, 'Tiếp tục');
      await tester.ensureVisible(reviewBtn);
      await tester.tap(reviewBtn);
      await tester.pumpAndSettle();
      expect(find.byType(ReceiptReviewPage), findsOneWidget);
      await _capture(tester, key008, 'flutter-SCR-010-READY-1280.png');

      // 5. SCR-012 Kết quả (1280)
      final submitBtn = find.widgetWithText(VButton, 'Ghi nhận');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.byType(ReceiptResultPage), findsOneWidget);
      await _capture(tester, key008, 'flutter-SCR-012-COMPLETED-1280.png');
    });
  });
}
