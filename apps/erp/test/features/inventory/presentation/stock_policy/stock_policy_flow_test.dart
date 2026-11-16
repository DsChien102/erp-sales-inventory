import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_models.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_repository.dart';
import 'package:erp/features/inventory/presentation/hub/warehouse_hub_page.dart';
import 'package:erp/features/inventory/presentation/stock_policy/stock_policy_page.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/inventory_router_harness.dart';

String _screenshotPath(String fileName) {
  final root = Directory.current.path.endsWith('apps/erp')
      ? Directory.current.parent.parent.path
      : Directory.current.path;
  return '$root/docs/refactor/plans/T7/img/G5-2a/$fileName';
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String fileName) async {
  await tester.pumpAndSettle();
  final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
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

final _flowProducts = [
  const StockPolicyProduct(
    productId: 'p_oxy',
    name: 'Oxytetracycline LA',
    code: 'OXY',
    uom: 'chai',
    isLotTracked: true,
    available: 25,
    hasExpired: false,
    hasNearExpiry: false,
    threshold: null,
    target: null,
  ),
  const StockPolicyProduct(
    productId: 'p_nobivac',
    name: 'Nobivac DHPPi',
    code: 'NOBI',
    uom: 'hộp',
    isLotTracked: true,
    available: 30,
    hasExpired: false,
    hasNearExpiry: false,
    threshold: 30,
    target: 80,
  ),
  const StockPolicyProduct(
    productId: 'p_amox',
    name: 'Amoxicillin 500',
    code: 'AMOX',
    uom: 'vỉ',
    isLotTracked: false,
    available: 120,
    hasExpired: false,
    hasNearExpiry: false,
    threshold: 50,
    target: 80,
  ),
  const StockPolicyProduct(
    productId: 'p_enro',
    name: 'Enrofloxacin 10%',
    code: 'ENRO',
    uom: 'chai',
    isLotTracked: true,
    available: 0,
    hasExpired: false,
    hasNearExpiry: false,
    threshold: 10,
    target: 30,
  ),
  const StockPolicyProduct(
    productId: 'p_tylo',
    name: 'Tylosin 200',
    code: 'TYLO',
    uom: 'lọ',
    isLotTracked: true,
    available: 24,
    hasExpired: true,
    hasNearExpiry: false,
    threshold: 8,
    target: 24,
    nearExpiryDaysOverride: 60,
  ),
];

class _StatefulFlowRepo extends Fake implements StockPolicyRepository {
  StockPolicySnapshot snapshot;

  _StatefulFlowRepo({StockPolicySnapshot? initial})
      : snapshot = initial ??
            StockPolicySnapshot(
              revision: 5,
              isOwner: true,
              nearExpiryDays: 90,
              products: List.of(_flowProducts),
            );

  @override
  Future<StockPolicySnapshot> load() async => snapshot;

  @override
  Future<int> saveThresholds({
    required String idempotencyKey,
    required int expectedRevision,
    required List<ThresholdChange> changes,
  }) async {
    final updated = snapshot.products.map((p) {
      final c = changes.where((ch) => ch.productId == p.productId).firstOrNull;
      if (c != null) {
        return StockPolicyProduct(
          productId: p.productId,
          name: p.name,
          code: p.code,
          uom: p.uom,
          isLotTracked: p.isLotTracked,
          available: p.available,
          hasExpired: p.hasExpired,
          hasNearExpiry: p.hasNearExpiry,
          threshold: c.threshold,
          target: c.target,
          nearExpiryDaysOverride: p.nearExpiryDaysOverride,
        );
      }
      return p;
    }).toList();
    snapshot = StockPolicySnapshot(
      revision: expectedRevision + 1,
      isOwner: snapshot.isOwner,
      nearExpiryDays: snapshot.nearExpiryDays,
      products: updated,
    );
    return expectedRevision + 1;
  }

  @override
  Future<int> saveNearExpiry({
    required String idempotencyKey,
    required int expectedRevision,
    required int? defaultDays,
    required List<NearExpiryOverride> overrides,
  }) async {
    final updated = snapshot.products.map((p) {
      final ov =
          overrides.where((o) => o.productId == p.productId).firstOrNull;
      if (ov != null) {
        return StockPolicyProduct(
          productId: p.productId,
          name: p.name,
          code: p.code,
          uom: p.uom,
          isLotTracked: p.isLotTracked,
          available: p.available,
          hasExpired: p.hasExpired,
          hasNearExpiry: p.hasNearExpiry,
          threshold: p.threshold,
          target: p.target,
          nearExpiryDaysOverride: ov.days,
        );
      }
      return p;
    }).toList();
    snapshot = StockPolicySnapshot(
      revision: expectedRevision + 1,
      isOwner: snapshot.isOwner,
      nearExpiryDays: defaultDays,
      products: updated,
    );
    return expectedRevision + 1;
  }
}

void main() {
  late _StatefulFlowRepo flowRepo;

  setUp(() async {
    flowRepo = _StatefulFlowRepo();
    await setUpInventoryRouterTest();
    if (getIt.isRegistered<StockPolicyRepository>()) {
      getIt.unregister<StockPolicyRepository>();
    }
    getIt.registerSingleton<StockPolicyRepository>(flowRepo);
  });

  tearDown(() async {
    await tearDownInventoryRouterTest();
  });

  group('Stock Policy End-to-End Flow', () {
    testWidgets('flow_1_web_1280_hub_edit_impact_and_save', (tester) async {
      final repaintKey = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(1280, 800),
        location: '/warehouse',
        repaintBoundaryKey: repaintKey,
      );
      await tester.pumpAndSettle();

      // 1. Hub -> Cuộn hub content xuống một chút rồi tap "Thiết lập kho"
      final hubScrollable = find.descendant(
        of: find.byType(WarehouseHubPage),
        matching: find.byType(SingleChildScrollView),
      );
      await tester.drag(hubScrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Thiết lập kho'), findsOneWidget);
      await tester.tap(find.text('Thiết lập kho'));
      await tester.pumpAndSettle();

      // 2. Area page -> Chính sách tồn & cận hạn
      expect(find.text('Chính sách tồn & cận hạn'), findsOneWidget);
      await tester.tap(find.text('Chính sách tồn & cận hạn'));
      await tester.pumpAndSettle();

      expect(find.byType(StockPolicyPage), findsOneWidget);
      expect(find.byType(VTable), findsOneWidget);

      // Chụp màn hình READY 1280 cho SCR-062
      await _capture(tester, repaintKey, 'flutter-SCR-062-READY-1280.png');

      // 3. Sửa ngưỡng Oxy: khả dụng 25, đặt ngưỡng 30 / mục tiêu 50 -> chuyển sang Thiếu hàng!
      await tester.enterText(
        find.bySemanticsLabel('Ngưỡng cảnh báo — Oxytetracycline LA'),
        '30',
      );
      await tester.enterText(
        find.bySemanticsLabel('Mức tồn mục tiêu — Oxytetracycline LA'),
        '50',
      );
      await tester.pumpAndSettle();

      // Sửa ngưỡng Amox: đặt 40 / 70
      await tester.enterText(
        find.bySemanticsLabel('Ngưỡng cảnh báo — Amoxicillin 500'),
        '40',
      );
      await tester.enterText(
        find.bySemanticsLabel('Mức tồn mục tiêu — Amoxicillin 500'),
        '70',
      );
      await tester.pumpAndSettle();

      // Nút Lưu thay đổi (2)
      final saveBtn = find.widgetWithText(VButton, 'Lưu thay đổi (2)');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // 4. Impact sheet
      expect(find.text('Lưu 2 thay đổi?'), findsOneWidget);
      expect(
        find.textContaining('Oxytetracycline LA: chưa có → 30 / 50 chai'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Amoxicillin 500: 50 / 80 → 40 / 70 vỉ'),
        findsOneWidget,
      );
      expect(
        find.text('Tồn thấp: 1 → 2 sản phẩm'),
        findsOneWidget,
      );

      // Bấm Lưu chính sách
      await tester.tap(find.widgetWithText(VButton, 'Lưu chính sách'));
      await tester.pumpAndSettle();

      // Toast thành công
      expect(find.text('Đã lưu chính sách · Lần 6'), findsAtLeastNWidgets(1));

      // Không còn dirty -> nút Lưu thay đổi disabled
      final saveBtnAfter = tester.widget<VButton>(
        find.widgetWithText(VButton, 'Lưu thay đổi (0)'),
      );
      expect(saveBtnAfter.onPressed, isNull);
    });

    testWidgets('flow_2_mobile_390_edit_sheet_and_save', (tester) async {
      final repaintKey = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(390, 844),
        location: '/warehouse/stock-policy',
        repaintBoundaryKey: repaintKey,
      );
      await tester.pumpAndSettle();

      expect(find.byType(StockPolicyPage), findsOneWidget);

      // Chụp màn hình READY 390 cho SCR-062
      await _capture(tester, repaintKey, 'flutter-SCR-062-READY-390.png');

      // Tap card Oxytetracycline LA (chưa có ngưỡng) ở ngay dòng đầu
      final oxyRow = find.widgetWithText(VListRow, 'Oxytetracycline LA');
      await tester.tap(oxyRow);
      await tester.pumpAndSettle();

      // Sheet mở lên
      expect(find.text('Oxytetracycline LA'), findsAtLeastNWidgets(1));

      await tester.enterText(
        find.bySemanticsLabel('Ngưỡng cảnh báo — Oxytetracycline LA'),
        '10',
      );
      await tester.enterText(
        find.bySemanticsLabel('Mức tồn mục tiêu — Oxytetracycline LA'),
        '20',
      );
      await tester.pumpAndSettle();

      // Bấm Lưu trên sheet
      await tester.tap(find.widgetWithText(VButton, 'Lưu'));
      await tester.pumpAndSettle();

      // Toast thành công
      expect(find.text('Đã lưu chính sách · Lần 6'), findsAtLeastNWidgets(1));

      // Card hiển thị thông tin mới
      expect(find.text('Ngưỡng 10 · Mục tiêu 20 chai'), findsOneWidget);
    });

    testWidgets('flow_3_expiry_tab_1280', (tester) async {
      final repaintKey1280 = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(1280, 800),
        location: '/warehouse/stock-policy?tab=expiry',
        repaintBoundaryKey: repaintKey1280,
      );
      await tester.pumpAndSettle();

      // Chụp màn hình READY 1280 cho SCR-063 (có mặc định 90 và Tylosin 60)
      await _capture(tester, repaintKey1280, 'flutter-SCR-063-READY-1280.png');
      expect(find.text('Số ngày cận hạn'), findsOneWidget);
      expect(find.text('Tylosin 200'), findsOneWidget);
    });

    testWidgets('flow_3_expiry_tab_390_edit_and_save', (tester) async {
      final repaintKey390 = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(390, 844),
        location: '/warehouse/stock-policy?tab=expiry',
        repaintBoundaryKey: repaintKey390,
      );
      await tester.pumpAndSettle();

      // Chụp màn hình READY 390 cho SCR-063 (có mặc định 90 và Tylosin 60)
      await _capture(tester, repaintKey390, 'flutter-SCR-063-READY-390.png');
      expect(find.text('Tylosin 200'), findsOneWidget);

      // Sửa số ngày mặc định thành 45
      final daysField = find.bySemanticsLabel('Số ngày cận hạn');
      await tester.enterText(daysField, '45');
      await tester.pumpAndSettle();

      // Thêm ngoại lệ cho Nobivac DHPPi
      await tester.tap(find.widgetWithText(VButton, 'Thêm sản phẩm'));
      await tester.pumpAndSettle();

      expect(find.text('Thêm sản phẩm'), findsNWidgets(2));
      await tester.tap(find.text('Nobivac DHPPi'));
      await tester.pumpAndSettle();

      // Card cho Nobivac DHPPi đã xuất hiện trong NearExpiryTab
      await tester.enterText(
        find.bySemanticsLabel('Số ngày cận hạn — Nobivac DHPPi'),
        '75',
      );
      await tester.pumpAndSettle();

      // Bấm Lưu thay đổi (ở thanh bottomNavigationBar ghim đáy)
      final saveBtn = find.widgetWithText(VButton, 'Lưu thay đổi');
      final btnWidget = tester.widget<VButton>(saveBtn);
      expect(btnWidget.onPressed, isNotNull);

      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Toast thành công
      expect(find.text('Đã lưu chính sách · Lần 6'), findsAtLeastNWidgets(1));
    });
  });
}
