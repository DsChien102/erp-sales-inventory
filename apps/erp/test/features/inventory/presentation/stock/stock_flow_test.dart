import 'dart:io';
import 'dart:ui' as ui;

import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/core/inventory_rpc.dart';
import 'package:erp/features/inventory/data/hub/warehouse_hub_repository.dart';
import 'package:erp/features/inventory/data/models/lot_date.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/data/stock/stock_repository.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_models.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_repository.dart';
import 'package:erp/features/inventory/presentation/stock/stock_detail_page.dart';
import 'package:erp/features/inventory/presentation/stock/stock_list_page.dart';
import 'package:erp/features/inventory/presentation/stock_policy/stock_threshold_single_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

import '../../support/inventory_router_harness.dart';

String _screenshotPath(String fileName) {
  final root = Directory.current.path.endsWith('apps/erp')
      ? Directory.current.parent.parent.path
      : Directory.current.path;
  return '$root/docs/refactor/plans/T7/img/G5-2/$fileName';
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

class _FlowHubRpc extends Fake implements InventoryRpc {
  @override
  Future<Map<String, dynamic>> query(
    String fn, [
    Map<String, dynamic> params = const {},
  ]) async =>
      {
        'activated': true,
        'problems': {
          'out': 1,
          'low': 2,
          'expired': 1,
          'near_expiry': 1,
          'products': 4,
        },
      };
}

class _StatefulStockState {
  final Map<String, ({num? threshold, num? target})> thresholds = {
    'INV-NOB': (threshold: 30, target: 80),
    'INV-AMX': (threshold: 50, target: 80),
    'INV-ENRO': (threshold: 10, target: 30),
    'INV-TYLO': (threshold: 8, target: 24),
    'INV-OXY': (threshold: null, target: null),
  };

  final Map<String, int> detailLoadCounts = {};
}

class _FlowStockRepository extends Fake implements StockRepository {
  final _StatefulStockState state;

  _FlowStockRepository(this.state);

  static final DateTime _asOf = DateTime(2026, 9, 17, 21, 30);

  @override
  Future<StockOverview> loadOverview() async {
    return StockOverview(
      asOf: _asOf,
      warehouseName: 'Kho trung tâm',
      products: [
        StockOverviewItem(
          productId: 'INV-NOB',
          name: 'Nobivac DHPPi',
          code: 'SP-000184',
          barcode: '8938500001012',
          uom: 'hộp',
          isLotTracked: true,
          physical: 120,
          available: 118,
          hasExpired: false,
          hasNearExpiry: true,
          threshold: state.thresholds['INV-NOB']?.threshold,
        ),
        StockOverviewItem(
          productId: 'INV-AMX',
          name: 'Amox 500',
          code: 'SP-000066',
          barcode: '8938500001029',
          uom: 'hộp',
          isLotTracked: true,
          physical: 48,
          available: 46,
          hasExpired: false,
          hasNearExpiry: false,
          threshold: state.thresholds['INV-AMX']?.threshold,
        ),
        StockOverviewItem(
          productId: 'INV-ENRO',
          name: 'Enrofloxacin 10%',
          code: 'SP-000091',
          barcode: '8938500001036',
          uom: 'chai',
          isLotTracked: false,
          physical: 0,
          available: 0,
          hasExpired: false,
          hasNearExpiry: false,
          threshold: state.thresholds['INV-ENRO']?.threshold,
        ),
        StockOverviewItem(
          productId: 'INV-TYLO',
          name: 'Tylosin 20%',
          code: 'SP-000122',
          barcode: '8938500001043',
          uom: 'lọ',
          isLotTracked: true,
          physical: 14,
          available: 3,
          hasExpired: true,
          hasNearExpiry: false,
          threshold: state.thresholds['INV-TYLO']?.threshold,
        ),
        StockOverviewItem(
          productId: 'INV-OXY',
          name: 'Oxytetracycline LA',
          code: 'SP-000147',
          barcode: '8938500001050',
          uom: 'chai',
          isLotTracked: false,
          physical: 12,
          available: 11,
          hasExpired: false,
          hasNearExpiry: false,
          threshold: state.thresholds['INV-OXY']?.threshold,
        ),
      ],
    );
  }

  @override
  Future<StockDetail> loadDetail(String productId) async {
    state.detailLoadCounts[productId] =
        (state.detailLoadCounts[productId] ?? 0) + 1;
    final policy = state.thresholds[productId];

    switch (productId) {
      case 'INV-NOB':
        return StockDetail(
          asOf: _asOf,
          warehouseName: 'Kho trung tâm',
          isOwner: true,
          productId: 'INV-NOB',
          name: 'Nobivac DHPPi',
          code: 'SP-000184',
          uom: 'hộp',
          isLotTracked: true,
          physical: 120,
          available: 118,
          expiredQuantity: 0,
          threshold: policy?.threshold,
          target: policy?.target,
          lots: const [
            StockLot(
              lotId: 'LOT-DH2509',
              code: 'DH2509',
              expiry: LotDate(year: 2026, month: 9, day: 30),
              physical: 50,
              isExpired: false,
              isNearExpiry: true,
              daysToExpiry: 13,
            ),
            StockLot(
              lotId: 'LOT-DH2507',
              code: 'DH2507',
              expiry: LotDate(year: 2026, month: 11, day: 30),
              physical: 68,
              isExpired: false,
              isNearExpiry: false,
              daysToExpiry: 74,
            ),
          ],
          latestMovement: StockLatestMovement(
            kind: 'RECEIPT',
            intentType: 'GOODS_RECEIPT',
            intentId: 'PN-202609-0014',
            delta: 50,
            businessDate: DateTime(2026, 9, 17),
          ),
          cost: const StockCost(
            method: CostMethod.moving,
            officialUnitCost: 118500,
            movingAvgCost: 117940,
            ledgerValueVnd: 14152800,
          ),
        );
      case 'INV-TYLO':
        return StockDetail(
          asOf: _asOf,
          warehouseName: 'Kho trung tâm',
          isOwner: true,
          productId: 'INV-TYLO',
          name: 'Tylosin 20%',
          code: 'SP-000122',
          uom: 'lọ',
          isLotTracked: true,
          physical: 14,
          available: 3,
          expiredQuantity: 11,
          threshold: policy?.threshold,
          target: policy?.target,
          lots: const [
            StockLot(
              lotId: 'LOT-TY2401',
              code: 'TY2401',
              expiry: LotDate(year: 2026, month: 8, day: 15),
              physical: 11,
              isExpired: true,
              isNearExpiry: false,
              daysToExpiry: -33,
            ),
            StockLot(
              lotId: 'LOT-TY2503',
              code: 'TY2503',
              expiry: LotDate(year: 2027, month: 3, day: 15),
              physical: 3,
              isExpired: false,
              isNearExpiry: false,
              daysToExpiry: 179,
            ),
          ],
          cost: const StockCost(
            method: CostMethod.moving,
            officialUnitCost: 92000,
            movingAvgCost: 92000,
            ledgerValueVnd: 1288000,
          ),
        );
      case 'INV-ENRO':
      default:
        return StockDetail(
          asOf: _asOf,
          warehouseName: 'Kho trung tâm',
          isOwner: true,
          productId: 'INV-ENRO',
          name: 'Enrofloxacin 10%',
          code: 'SP-000091',
          uom: 'chai',
          isLotTracked: false,
          physical: 0,
          available: 0,
          expiredQuantity: 0,
          threshold: policy?.threshold,
          target: policy?.target,
          cost: const StockCost(
            method: CostMethod.moving,
            officialUnitCost: 85000,
            movingAvgCost: 85000,
            ledgerValueVnd: 0,
          ),
        );
    }
  }
}

class _FlowStockPolicyRepository extends Fake
    implements StockPolicyRepository {
  final _StatefulStockState state;
  int _revision = 3;

  _FlowStockPolicyRepository(this.state);

  @override
  Future<StockPolicySnapshot> load() async {
    return StockPolicySnapshot(
      revision: _revision,
      isOwner: true,
      nearExpiryDays: 30,
      products: [
        StockPolicyProduct(
          productId: 'INV-NOB',
          name: 'Nobivac DHPPi',
          code: 'SP-000184',
          uom: 'hộp',
          isLotTracked: true,
          available: 118,
          hasExpired: false,
          hasNearExpiry: true,
          threshold: state.thresholds['INV-NOB']?.threshold,
          target: state.thresholds['INV-NOB']?.target,
        ),
        StockPolicyProduct(
          productId: 'INV-AMX',
          name: 'Amox 500',
          code: 'SP-000066',
          uom: 'hộp',
          isLotTracked: true,
          available: 46,
          hasExpired: false,
          hasNearExpiry: false,
          threshold: state.thresholds['INV-AMX']?.threshold,
          target: state.thresholds['INV-AMX']?.target,
        ),
        StockPolicyProduct(
          productId: 'INV-ENRO',
          name: 'Enrofloxacin 10%',
          code: 'SP-000091',
          uom: 'chai',
          isLotTracked: false,
          available: 0,
          hasExpired: false,
          hasNearExpiry: false,
          threshold: state.thresholds['INV-ENRO']?.threshold,
          target: state.thresholds['INV-ENRO']?.target,
        ),
        StockPolicyProduct(
          productId: 'INV-TYLO',
          name: 'Tylosin 20%',
          code: 'SP-000122',
          uom: 'lọ',
          isLotTracked: true,
          available: 3,
          hasExpired: true,
          hasNearExpiry: false,
          threshold: state.thresholds['INV-TYLO']?.threshold,
          target: state.thresholds['INV-TYLO']?.target,
        ),
        StockPolicyProduct(
          productId: 'INV-OXY',
          name: 'Oxytetracycline LA',
          code: 'SP-000147',
          uom: 'chai',
          isLotTracked: false,
          available: 11,
          hasExpired: false,
          hasNearExpiry: false,
          threshold: state.thresholds['INV-OXY']?.threshold,
          target: state.thresholds['INV-OXY']?.target,
        ),
      ],
    );
  }

  @override
  Future<int> saveThresholds({
    required String idempotencyKey,
    required int expectedRevision,
    required List<ThresholdChange> changes,
  }) async {
    for (final change in changes) {
      state.thresholds[change.productId] = (
        threshold: change.threshold,
        target: change.target,
      );
    }
    _revision = expectedRevision + 1;
    return _revision;
  }
}

void main() {
  late _StatefulStockState sharedState;
  late _FlowStockRepository stockRepo;
  late _FlowStockPolicyRepository policyRepo;

  setUp(() async {
    sharedState = _StatefulStockState();
    stockRepo = _FlowStockRepository(sharedState);
    policyRepo = _FlowStockPolicyRepository(sharedState);
    await setUpInventoryRouterTest(isOwner: true);
    getIt
      ..unregister<WarehouseHubRepository>()
      ..registerSingleton<WarehouseHubRepository>(
        WarehouseHubRepository(rpc: _FlowHubRpc()),
      )
      ..unregister<StockRepository>()
      ..registerSingleton<StockRepository>(stockRepo)
      ..unregister<StockPolicyRepository>()
      ..registerSingleton<StockPolicyRepository>(policyRepo);
  });

  tearDown(() async {
    await tearDownInventoryRouterTest();
  });

  group('BJ-01 Stock End-to-End Flow & Screenshots', () {
    testWidgets(
      'e2e_flow_390_hub_to_stock_filter_low_detail_edit_threshold_and_back',
      (tester) async {
        await pumpInventoryApp(
          tester,
          size: const Size(390, 844),
          location: '/warehouse',
          isOwner: true,
        );

        // 1. Hub hiển thị "Tồn kho cần chú ý" -> bấm mở danh sách tồn kho
        expect(find.text('Tồn kho cần chú ý'), findsOneWidget);
        expect(
          find.text(
            '1 hết hàng · 2 tồn thấp · 1 có lô hết hạn · 1 có lô cận hạn',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Tồn kho cần chú ý'));
        await tester.pumpAndSettle();

        expect(find.byType(StockListPage), findsOneWidget);
        expect(find.byType(VStockRow), findsNWidgets(5));

        // 2. Chọn chip "Tồn thấp" -> còn 2 sản phẩm (Tylosin 20%, Amox 500)
        final lowChip = find.textContaining('Tồn thấp').first;
        await tester.ensureVisible(lowChip);
        await tester.tap(lowChip);
        await tester.pumpAndSettle();

        expect(find.byType(VStockRow), findsNWidgets(2));
        expect(find.text('Tylosin 20%'), findsOneWidget);
        expect(find.text('Amox 500'), findsOneWidget);

        // 3. Chạm "Tylosin 20%" -> mở SCR-003 Chi tiết tồn kho
        await tester.tap(find.text('Tylosin 20%'));
        await tester.pumpAndSettle();

        expect(find.byType(StockDetailPage), findsOneWidget);
        expect(sharedState.detailLoadCounts['INV-TYLO'], 1);
        expect(find.text('Ngưỡng 8 · Mục tiêu 24 lọ'), findsOneWidget);

        // 4. Bấm "Sửa ngưỡng" -> mở G5-2a StockThresholdSinglePage
        await tester.tap(find.text('Sửa ngưỡng'));
        await tester.pumpAndSettle();

        expect(find.byType(StockThresholdSinglePage), findsOneWidget);

        await tester.enterText(
          find.bySemanticsLabel('Ngưỡng cảnh báo — Tylosin 20%'),
          '10',
        );
        await tester.enterText(
          find.bySemanticsLabel('Mức tồn mục tiêu — Tylosin 20%'),
          '30',
        );
        await tester.pumpAndSettle();

        // Lưu ngưỡng -> pop(true) về SCR-003
        await tester.tap(find.widgetWithText(VButton, 'Lưu'));
        await tester.pumpAndSettle();

        // 5. Chi tiết tải lại với ngưỡng mới
        expect(find.byType(StockDetailPage), findsOneWidget);
        expect(sharedState.detailLoadCounts['INV-TYLO'], 2);
        expect(find.text('Ngưỡng 10 · Mục tiêu 30 lọ'), findsOneWidget);

        // 6. Quay lại danh sách -> giữ nguyên chip "Tồn thấp"
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        expect(find.byType(StockListPage), findsOneWidget);
        expect(find.byType(VStockRow), findsNWidgets(2));
        expect(find.text('Tylosin 20%'), findsOneWidget);
        expect(find.text('Amox 500'), findsOneWidget);
      },
    );

    testWidgets('capture_SCR_001_READY_390_and_1280', (tester) async {
      final repaintKey390 = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(390, 844),
        location: '/warehouse/stock',
        isOwner: true,
        repaintBoundaryKey: repaintKey390,
      );
      expect(find.byType(StockListPage), findsOneWidget);
      await _capture(tester, repaintKey390, 'flutter-SCR-001-READY-390.png');
      if (Platform.environment['CAPTURE_SCREENSHOTS'] == '1') await expectLater(
        find.byKey(repaintKey390),
        matchesGoldenFile(_screenshotPath('flutter-SCR-001-READY-390.png')),
      );

      final repaintKey1280 = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(1280, 800),
        location: '/warehouse/stock',
        isOwner: true,
        repaintBoundaryKey: repaintKey1280,
      );
      expect(find.byType(StockListPage), findsOneWidget);
      await _capture(tester, repaintKey1280, 'flutter-SCR-001-READY-1280.png');
      if (Platform.environment['CAPTURE_SCREENSHOTS'] == '1') await expectLater(
        find.byKey(repaintKey1280),
        matchesGoldenFile(_screenshotPath('flutter-SCR-001-READY-1280.png')),
      );
    });

    testWidgets('capture_SCR_003_READY_390_and_1280', (tester) async {
      final repaintKey390 = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(390, 844),
        location: '/warehouse/stock/INV-NOB',
        isOwner: true,
        repaintBoundaryKey: repaintKey390,
      );
      expect(find.byType(StockDetailPage), findsOneWidget);
      await _capture(tester, repaintKey390, 'flutter-SCR-003-READY-390.png');
      if (Platform.environment['CAPTURE_SCREENSHOTS'] == '1') await expectLater(
        find.byKey(repaintKey390),
        matchesGoldenFile(_screenshotPath('flutter-SCR-003-READY-390.png')),
      );

      final repaintKey1280 = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(1280, 800),
        location: '/warehouse/stock/INV-NOB',
        isOwner: true,
        repaintBoundaryKey: repaintKey1280,
      );
      expect(find.byType(StockDetailPage), findsOneWidget);
      await _capture(tester, repaintKey1280, 'flutter-SCR-003-READY-1280.png');
      if (Platform.environment['CAPTURE_SCREENSHOTS'] == '1') await expectLater(
        find.byKey(repaintKey1280),
        matchesGoldenFile(_screenshotPath('flutter-SCR-003-READY-1280.png')),
      );
    });
  });
}
