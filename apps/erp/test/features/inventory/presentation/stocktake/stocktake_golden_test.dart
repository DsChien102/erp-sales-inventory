import 'dart:io';

import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/core/inventory_command_result.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_repository.dart';
import 'package:erp/features/inventory/presentation/stocktake/stocktake_count_page.dart';
import 'package:erp/features/inventory/presentation/stocktake/stocktake_create_page.dart';
import 'package:erp/features/inventory/presentation/stocktake/stocktake_list_page.dart';
import 'package:erp/features/inventory/presentation/stocktake/stocktake_recount_page.dart';
import 'package:erp/features/inventory/presentation/stocktake/stocktake_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/inventory_router_harness.dart';

String _goldenPath(String fileName) {
  final root = Directory.current.path.endsWith('apps/erp')
      ? Directory.current.parent.parent.path
      : Directory.current.path;
  return '$root/docs/refactor/plans/T7/img/G5-5/$fileName';
}

class _GoldenStocktakeRepository extends Fake implements StocktakeRepository {
  late final Map<String, StocktakeSession> _sessions = {
    'kk-044': StocktakeSession(
      id: 'kk-044',
      code: 'KK-260917-01',
      scopeKind: StocktakeScopeKind.all,
      scopeLabel: 'Toàn kho',
      counterName: 'Nguyễn Văn An',
      reason: 'Kiểm kê định kỳ',
      status: StocktakeStatus.counting,
      openedAt: DateTime(2026, 9, 17, 18, 0),
      lines: const [
        StocktakeLine(
          lineId: 'l-oxy',
          productId: 'p-oxy',
          productName: 'Oxytetracycline LA',
          productCode: 'SP-000147',
          isExpired: false,
          uom: 'chai',
          isUnexpected: false,
          needsRecount: false,
        ),
        StocktakeLine(
          lineId: 'l-ty-2511',
          productId: 'p-ty',
          productName: 'Tylosin 20%',
          productCode: 'SP-000122',
          lotId: 'lot-ty2511',
          lotCode: 'TY2511',
          isExpired: false,
          uom: 'lọ',
          isUnexpected: false,
          needsRecount: false,
        ),
        StocktakeLine(
          lineId: 'l-ty-2408',
          productId: 'p-ty',
          productName: 'Tylosin 20%',
          productCode: 'SP-000122',
          lotId: 'lot-ty2408',
          lotCode: 'TY2408',
          isExpired: true,
          uom: 'lọ',
          isUnexpected: false,
          needsRecount: false,
        ),
      ],
    ),
    'kk-045': StocktakeSession(
      id: 'kk-045',
      code: 'KK-260917-01',
      scopeKind: StocktakeScopeKind.all,
      scopeLabel: 'Toàn kho',
      counterName: 'Nguyễn Văn An',
      reason: 'Kiểm kê định kỳ',
      status: StocktakeStatus.recount,
      openedAt: DateTime(2026, 9, 17, 18, 0),
      firstSubmittedAt: DateTime(2026, 9, 17, 19, 0),
      lines: const [
        StocktakeLine(
          lineId: 'l-oxy',
          productId: 'p-oxy',
          productName: 'Oxytetracycline LA',
          productCode: 'SP-000147',
          isExpired: false,
          uom: 'chai',
          isUnexpected: false,
          needsRecount: true,
          lossReason: StocktakeLossReason.loss,
          bookQty: 12,
          firstQty: 10,
          variance: -2,
        ),
        StocktakeLine(
          lineId: 'l-ty-2511',
          productId: 'p-ty',
          productName: 'Tylosin 20%',
          productCode: 'SP-000122',
          lotId: 'lot-ty2511',
          lotCode: 'TY2511',
          isExpired: false,
          uom: 'lọ',
          isUnexpected: false,
          needsRecount: true,
          bookQty: 3,
          firstQty: 4,
          variance: 1,
        ),
        StocktakeLine(
          lineId: 'l-ty-2408',
          productId: 'p-ty',
          productName: 'Tylosin 20%',
          productCode: 'SP-000122',
          lotId: 'lot-ty2408',
          lotCode: 'TY2408',
          isExpired: true,
          uom: 'lọ',
          isUnexpected: false,
          needsRecount: false,
          bookQty: 11,
          firstQty: 11,
          variance: 0,
        ),
      ],
    ),
    'kk-047': StocktakeSession(
      id: 'kk-047',
      code: 'KK-260917-01',
      scopeKind: StocktakeScopeKind.all,
      scopeLabel: 'Toàn kho',
      counterName: 'Nguyễn Văn An',
      reason: 'Kiểm kê định kỳ',
      status: StocktakeStatus.completed,
      resultKind: StocktakeResultKind.adjusted,
      openedAt: DateTime(2026, 9, 17, 18, 0),
      firstSubmittedAt: DateTime(2026, 9, 17, 19, 0),
      completedAt: DateTime(2026, 9, 17, 20, 10),
      completedByName: 'Chủ cửa hàng',
      stockChanges: const [
        InventoryStockChange(
          productId: 'p-oxy',
          productName: 'Oxytetracycline LA',
          baseUom: 'chai',
          before: 12,
          after: 10,
        ),
      ],
      lines: const [
        StocktakeLine(
          lineId: 'l-oxy',
          productId: 'p-oxy',
          productName: 'Oxytetracycline LA',
          productCode: 'SP-000147',
          isExpired: false,
          uom: 'chai',
          isUnexpected: false,
          needsRecount: true,
          lossReason: StocktakeLossReason.loss,
          bookQty: 12,
          firstQty: 10,
          recountQty: 10,
          variance: -2,
          adjustQty: -2,
        ),
        StocktakeLine(
          lineId: 'l-ty-2511',
          productId: 'p-ty',
          productName: 'Tylosin 20%',
          productCode: 'SP-000122',
          lotId: 'lot-ty2511',
          lotCode: 'TY2511',
          isExpired: false,
          uom: 'lọ',
          isUnexpected: false,
          needsRecount: true,
          bookQty: 3,
          firstQty: 4,
          recountQty: 3,
          variance: 0,
          adjustQty: 0,
        ),
        StocktakeLine(
          lineId: 'l-ty-2408',
          productId: 'p-ty',
          productName: 'Tylosin 20%',
          productCode: 'SP-000122',
          lotId: 'lot-ty2408',
          lotCode: 'TY2408',
          isExpired: true,
          uom: 'lọ',
          isUnexpected: false,
          needsRecount: false,
          bookQty: 11,
          firstQty: 11,
          variance: 0,
        ),
      ],
    ),
  };

  @override
  Future<List<StocktakeListRow>> list() async => [
    StocktakeListRow(
      id: 'kk-016',
      code: 'KK-260916-01',
      scopeLabel: 'Toàn kho',
      counterName: 'Trần Thị Bình',
      status: StocktakeStatus.counting,
      openedAt: DateTime(2026, 9, 16, 18, 10),
      lineCount: 9,
      countedCount: 4,
      varianceCount: 0,
    ),
    StocktakeListRow(
      id: 'kk-015',
      code: 'KK-260915-02',
      scopeLabel: 'Nhóm vật tư',
      counterName: 'Nguyễn Văn An',
      status: StocktakeStatus.recount,
      openedAt: DateTime(2026, 9, 15, 16, 30),
      lineCount: 9,
      countedCount: 9,
      varianceCount: 1,
    ),
    StocktakeListRow(
      id: 'kk-030',
      code: 'KK-260830-01',
      scopeLabel: 'Toàn kho',
      counterName: 'Nguyễn Văn An',
      status: StocktakeStatus.completed,
      openedAt: DateTime(2026, 8, 30, 18, 0),
      lineCount: 9,
      countedCount: 9,
      varianceCount: 0,
    ),
  ];

  @override
  Future<StocktakeFormOptions> formOptions() async => const StocktakeFormOptions(
    allCount: 9,
    products: [
      StocktakeProductOption(
        id: 'p-oxy',
        name: 'Oxytetracycline LA',
        code: 'SP-000147',
        uom: 'chai',
        lineCount: 1,
      ),
      StocktakeProductOption(
        id: 'p-ty',
        name: 'Tylosin 20%',
        code: 'SP-000122',
        uom: 'lọ',
        lineCount: 2,
      ),
      StocktakeProductOption(
        id: 'p-nitrile',
        name: 'Găng tay khám Nitrile',
        code: 'SP-000201',
        uom: 'hộp',
        lineCount: 1,
      ),
      StocktakeProductOption(
        id: 'p-dau',
        name: 'Dầu sát khuẩn',
        code: 'SP-000202',
        uom: 'chai',
        lineCount: 1,
      ),
      StocktakeProductOption(
        id: 'p-nobivac',
        name: 'Nobivac DHPPi',
        code: 'SP-000184',
        uom: 'hộp',
        lineCount: 2,
      ),
      StocktakeProductOption(
        id: 'p-amox',
        name: 'Amox 500',
        code: 'SP-000195',
        uom: 'hộp',
        lineCount: 1,
      ),
      StocktakeProductOption(
        id: 'p-iver',
        name: 'Ivermectin 1%',
        code: 'SP-000210',
        uom: 'lọ',
        lineCount: 1,
      ),
    ],
    lots: [
      StocktakeLotOption(
        id: 'lot-ty2511',
        productId: 'p-ty',
        productName: 'Tylosin 20%',
        code: 'SP-000122',
        lotCode: 'TY2511',
        isExpired: false,
        uom: 'lọ',
      ),
      StocktakeLotOption(
        id: 'lot-ty2408',
        productId: 'p-ty',
        productName: 'Tylosin 20%',
        code: 'SP-000122',
        lotCode: 'TY2408',
        isExpired: true,
        uom: 'lọ',
      ),
      StocktakeLotOption(
        id: 'lot-dau',
        productId: 'p-dau',
        productName: 'Dầu sát khuẩn',
        code: 'SP-000202',
        lotCode: 'L2406-T',
        isExpired: false,
        uom: 'chai',
      ),
      StocktakeLotOption(
        id: 'lot-dh2507',
        productId: 'p-nobivac',
        productName: 'Nobivac DHPPi',
        code: 'SP-000184',
        lotCode: 'DH2507',
        isExpired: false,
        uom: 'hộp',
      ),
      StocktakeLotOption(
        id: 'lot-dh2509',
        productId: 'p-nobivac',
        productName: 'Nobivac DHPPi',
        code: 'SP-000184',
        lotCode: 'DH2509',
        isExpired: false,
        uom: 'hộp',
      ),
    ],
    members: [
      StocktakeMember(userId: 'u-an', name: 'Nguyễn Văn An'),
      StocktakeMember(userId: 'u-binh', name: 'Trần Thị Bình'),
    ],
    me: 'u-an',
  );

  @override
  Future<StocktakeSession> get(String sessionId) async => _sessions[sessionId]!;
}

void _goldenTest(String name, WidgetTesterCallback body) {
  testWidgets(name, body, tags: 'golden');
}

void main() {
  setUp(() async {
    await setUpInventoryRouterTest();
    if (getIt.isRegistered<StocktakeRepository>()) {
      getIt.unregister<StocktakeRepository>();
    }
    getIt.registerSingleton<StocktakeRepository>(_GoldenStocktakeRepository());
  });

  tearDown(() async {
    await tearDownInventoryRouterTest();
  });

  group('Stocktake Golden Screenshots (Task 10)', () {
    _goldenTest('capture_SCR_042_READY_390_and_1280', (tester) async {
      final key390 = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(390, 844),
        location: '/warehouse/stocktakes',
        repaintBoundaryKey: key390,
      );
      expect(find.byType(StocktakeListPage), findsOneWidget);
      await expectLater(
        find.byKey(key390),
        matchesGoldenFile(_goldenPath('flutter-SCR-042-READY-390.png')),
      );

      final key1280 = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(1280, 800),
        location: '/warehouse/stocktakes',
        repaintBoundaryKey: key1280,
      );
      expect(find.byType(StocktakeListPage), findsOneWidget);
      await expectLater(
        find.byKey(key1280),
        matchesGoldenFile(_goldenPath('flutter-SCR-042-READY-1280.png')),
      );
    });

    _goldenTest('capture_SCR_043_READY_390_and_1280', (tester) async {
      final key390 = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(390, 844),
        location: '/warehouse/stocktakes/new',
        repaintBoundaryKey: key390,
      );
      expect(find.byType(StocktakeCreatePage), findsOneWidget);
      await expectLater(
        find.byKey(key390),
        matchesGoldenFile(_goldenPath('flutter-SCR-043-READY-390.png')),
      );

      final key1280 = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(1280, 800),
        location: '/warehouse/stocktakes/new',
        repaintBoundaryKey: key1280,
      );
      expect(find.byType(StocktakeCreatePage), findsOneWidget);
      await expectLater(
        find.byKey(key1280),
        matchesGoldenFile(_goldenPath('flutter-SCR-043-READY-1280.png')),
      );
    });

    _goldenTest('capture_SCR_044_BLIND_COUNT_390_and_1280', (tester) async {
      final key390 = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(390, 844),
        location: '/warehouse/stocktakes/kk-044/count',
        repaintBoundaryKey: key390,
      );
      expect(find.byType(StocktakeCountPage), findsOneWidget);
      await expectLater(
        find.byKey(key390),
        matchesGoldenFile(_goldenPath('flutter-SCR-044-BLIND_COUNT-390.png')),
      );

      final key1280 = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(1280, 800),
        location: '/warehouse/stocktakes/kk-044/count',
        repaintBoundaryKey: key1280,
      );
      expect(find.byType(StocktakeCountPage), findsOneWidget);
      await expectLater(
        find.byKey(key1280),
        matchesGoldenFile(_goldenPath('flutter-SCR-044-BLIND_COUNT-1280.png')),
      );
    });

    _goldenTest('capture_SCR_045_RECOUNT_REQUIRED_390_and_1280', (
      tester,
    ) async {
      final key390 = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(390, 844),
        location: '/warehouse/stocktakes/kk-045/recount',
        repaintBoundaryKey: key390,
      );
      expect(find.byType(StocktakeRecountPage), findsOneWidget);
      await expectLater(
        find.byKey(key390),
        matchesGoldenFile(
          _goldenPath('flutter-SCR-045-RECOUNT_REQUIRED-390.png'),
        ),
      );

      final key1280 = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(1280, 800),
        location: '/warehouse/stocktakes/kk-045/recount',
        repaintBoundaryKey: key1280,
      );
      expect(find.byType(StocktakeRecountPage), findsOneWidget);
      await expectLater(
        find.byKey(key1280),
        matchesGoldenFile(
          _goldenPath('flutter-SCR-045-RECOUNT_REQUIRED-1280.png'),
        ),
      );
    });

    _goldenTest('capture_SCR_047_COMPLETED_390_and_1280', (tester) async {
      final key390 = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(390, 844),
        location: '/warehouse/stocktakes/kk-047/result',
        repaintBoundaryKey: key390,
      );
      expect(find.byType(StocktakeResultPage), findsOneWidget);
      await expectLater(
        find.byKey(key390),
        matchesGoldenFile(_goldenPath('flutter-SCR-047-COMPLETED-390.png')),
      );

      final key1280 = GlobalKey();
      await pumpInventoryApp(
        tester,
        size: const Size(1280, 800),
        location: '/warehouse/stocktakes/kk-047/result',
        repaintBoundaryKey: key1280,
      );
      expect(find.byType(StocktakeResultPage), findsOneWidget);
      await expectLater(
        find.byKey(key1280),
        matchesGoldenFile(_goldenPath('flutter-SCR-047-COMPLETED-1280.png')),
      );
    });
  });
}
