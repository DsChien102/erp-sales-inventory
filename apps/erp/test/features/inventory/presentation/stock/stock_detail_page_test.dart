import 'package:erp/core/di/injection.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/models/lot_date.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/data/stock/stock_repository.dart';
import 'package:erp/features/inventory/presentation/stock/stock_detail_body.dart';
import 'package:erp/features/inventory/presentation/stock/stock_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeStockRepository implements StockRepository {
  StockDetail Function(String productId) detailBuilder;
  int detailLoadCount = 0;

  _FakeStockRepository(this.detailBuilder);

  @override
  Future<StockOverview> loadOverview() async {
    throw UnimplementedError();
  }

  @override
  Future<StockDetail> loadDetail(String productId) async {
    detailLoadCount++;
    return detailBuilder(productId);
  }
}

StockDetail _buildTylosinDetail({
  bool isOwner = true,
  StockCost? cost,
}) {
  return StockDetail(
    asOf: DateTime(2026, 9, 17, 21, 30),
    warehouseName: 'Kho trung tâm',
    isOwner: isOwner,
    productId: 'INV-TYL',
    name: 'Tylosin 200',
    code: 'SP-000118',
    uom: 'lọ',
    isLotTracked: true,
    physical: 14,
    available: 3,
    expiredQuantity: 11,
    threshold: 8,
    target: 24,
    lots: const [
      StockLot(
        lotId: 'L-TY2511',
        code: 'TY2511',
        expiry: LotDate(year: 2027, month: 11, day: 15),
        physical: 3,
        isExpired: false,
        isNearExpiry: false,
        daysToExpiry: 424,
      ),
      StockLot(
        lotId: 'L-TY2408',
        code: 'TY2408',
        expiry: LotDate(year: 2025, month: 8, day: 10),
        physical: 11,
        isExpired: true,
        isNearExpiry: false,
        daysToExpiry: -403,
      ),
    ],
    latestMovement: StockLatestMovement(
      kind: 'RECEIPT',
      intentType: 'PURCHASE_RECEIPT',
      intentId: 'REC-01',
      delta: 14,
      businessDate: DateTime(2026, 9, 15),
    ),
    cost: cost,
  );
}

StockDetail _buildNobivacDetail() {
  return StockDetail(
    asOf: DateTime(2026, 9, 17, 21, 30),
    warehouseName: 'Kho trung tâm',
    isOwner: true,
    productId: 'INV-NOB',
    name: 'Nobivac DHPPi',
    code: 'SP-000105',
    uom: 'liều',
    isLotTracked: true,
    physical: 30,
    available: 30,
    expiredQuantity: 0,
    threshold: 30,
    target: 80,
    lots: const [
      StockLot(
        lotId: 'L-NB2609',
        code: 'NB2609',
        expiry: LotDate(year: 2026, month: 9, day: 30),
        physical: 30,
        isExpired: false,
        isNearExpiry: true,
        daysToExpiry: 13,
      ),
    ],
  );
}

StockDetail _buildOxyDetail({bool isOwner = true}) {
  return StockDetail(
    asOf: DateTime(2026, 9, 17, 21, 30),
    warehouseName: 'Kho trung tâm',
    isOwner: isOwner,
    productId: 'INV-OXY',
    name: 'Oxytetracycline 20% LA chai 100ml',
    code: 'SP-000147',
    uom: 'chai',
    isLotTracked: false,
    physical: 36,
    available: 36,
    expiredQuantity: 0,
    threshold: null,
    target: null,
  );
}

Widget _buildTestApp({
  required StockRepository repository,
  String productId = 'INV-TYL',
  bool policyResult = true,
  ValueChanged<String>? onPolicyOpened,
  ValueChanged<String>? onStocktakeOpened,
  ValueChanged<String>? onCompareOpened,
  ValueChanged<String>? onCardOpened,
}) {
  if (getIt.isRegistered<StockRepository>()) {
    getIt.unregister<StockRepository>();
  }
  getIt.registerSingleton<StockRepository>(repository);

  final router = GoRouter(
    initialLocation: '/warehouse/stock/$productId',
    routes: [
      GoRoute(
        path: '/warehouse',
        builder: (_, _) => const Scaffold(body: Text('Hub Kho')),
      ),
      GoRoute(
        path: '/warehouse/stock/:productId',
        builder: (_, state) => StockDetailPage(
          productId: state.pathParameters['productId']!,
        ),
      ),
      GoRoute(
        path: '/warehouse/stock/:productId/suppliers',
        builder: (_, state) {
          final id = state.pathParameters['productId']!;
          onCompareOpened?.call('/warehouse/stock/$id/suppliers');
          return Scaffold(body: Text('COMPARE:$id'));
        },
      ),
      GoRoute(
        path: '/warehouse/reports/stock/:productId',
        builder: (_, state) {
          onCardOpened?.call(state.uri.toString());
          return Scaffold(body: Text('CARD:${state.pathParameters['productId']}'));
        },
      ),
      GoRoute(
        path: '/warehouse/stocktakes/new',
        builder: (context, state) {
          onStocktakeOpened?.call(state.uri.toString());
          return Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Mở kiểm kê ${state.uri}'),
            ),
          );
        },
      ),
      GoRoute(
        path: '/warehouse/stock-policy/product/:productId',
        builder: (context, state) {
          final id = state.pathParameters['productId']!;
          onPolicyOpened?.call(id);
          return Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(policyResult),
              child: const Text('Lưu ngưỡng'),
            ),
          );
        },
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

void main() {
  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('StockDetailPage (SCR-003)', () {
    testWidgets('detail_ready_390', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _FakeStockRepository((_) => _buildTylosinDetail());
      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      // Thẻ Khả dụng "3 lọ" + "Tồn thấp"
      expect(find.text('Khả dụng'), findsOneWidget);
      expect(find.text('3 lọ'), findsOneWidget);
      expect(find.text('Tồn thấp'), findsWidgets);

      // Tồn vật lý 14 lọ
      expect(find.text('Tồn vật lý'), findsOneWidget);
      expect(find.text('14 lọ'), findsOneWidget);

      // Không đủ điều kiện bán: Hết hạn 11 lọ
      expect(
        find.text('Không đủ điều kiện bán: Hết hạn 11 lọ'),
        findsOneWidget,
      );

      // Ngưỡng 8 · Mục tiêu 24 lọ
      expect(find.text('Ngưỡng 8 · Mục tiêu 24 lọ'), findsOneWidget);

      // Banner Tồn thấp + gợi ý
      expect(find.text('Khả dụng 3 lọ · Ngưỡng 8 lọ.'), findsOneWidget);
      expect(
        find.text('Gợi ý nhập thêm 21 lọ (mục tiêu 24 lọ)'),
        findsOneWidget,
      );

      // Banner Có lô hết hạn
      expect(find.text('Có lô hết hạn'), findsOneWidget);
      expect(
        find.text('Lô TY2408 · 11 lọ không đủ điều kiện bán.'),
        findsOneWidget,
      );

      // Có nút Nhận hàng và Điều chỉnh lô hết hạn; không có Đã giữ
      expect(find.text('Nhận hàng'), findsOneWidget);
      expect(find.text('Điều chỉnh lô hết hạn'), findsOneWidget);
      expect(find.text('Đã giữ'), findsNothing);

      // Lô TY2408 đứng trước TY2511
      final ty2408Dy = tester.getTopLeft(find.text('Lô TY2408')).dy;
      final ty2511Dy = tester.getTopLeft(find.text('Lô TY2511')).dy;
      expect(ty2408Dy, lessThan(ty2511Dy));
    });

    testWidgets('owner_sees_cost_block_390', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _FakeStockRepository(
        (_) => _buildTylosinDetail(
          isOwner: true,
          cost: const StockCost(
            method: CostMethod.moving,
            officialUnitCost: 118500,
            movingAvgCost: 117940,
            ledgerValueVnd: 1651160,
          ),
        ),
      );
      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Giá vốn'), findsOneWidget);
      expect(find.text('Giá vốn chính thức'), findsOneWidget);
      expect(find.text('Bình quân liên hoàn'), findsOneWidget);
      expect(find.text('Giá trị tồn (sổ)'), findsOneWidget);
      expect(find.text('Phương pháp: Bình quân liên hoàn'), findsOneWidget);
    });

    testWidgets('periodic_provisional_shows_note', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _FakeStockRepository(
        (_) => _buildTylosinDetail(
          isOwner: true,
          cost: const StockCost(
            method: CostMethod.periodic,
            officialUnitCost: null,
            movingAvgCost: 117940,
            ledgerValueVnd: 1651160,
          ),
        ),
      );
      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Chưa công bố'), findsOneWidget);
      expect(find.text('Phương pháp: Bình quân cuối kỳ'), findsOneWidget);
      expect(
        find.text('Xuất kho đang dùng giá tạm (bình quân liên hoàn).'),
        findsOneWidget,
      );
    });

    testWidgets('staff_no_cost_no_threshold_links_390', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _FakeStockRepository(
        (_) => _buildTylosinDetail(isOwner: false, cost: null),
      );
      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Giá vốn'), findsNothing);
      expect(find.text('Sửa ngưỡng'), findsNothing);
      expect(find.text('Đặt ngưỡng tồn'), findsNothing);
    });

    testWidgets('edit_threshold_tap_target_at_least_44_and_labeled_390', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final handle = tester.ensureSemantics();

      final repo = _FakeStockRepository((_) => _buildTylosinDetail());
      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      final inkWell = find.ancestor(
        of: find.text('Sửa ngưỡng'),
        matching: find.byType(InkWell),
      );
      expect(inkWell, findsOneWidget);
      final size = tester.getSize(inkWell);
      expect(size.height, greaterThanOrEqualTo(44));
      expect(size.width, greaterThanOrEqualTo(44));

      // Một nút duy nhất cho trình đọc màn hình, không đọc hai lần.
      expect(find.bySemanticsLabel('Sửa ngưỡng'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('not_configured_shows_note_and_set_button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _FakeStockRepository(
        (_) => _buildOxyDetail(isOwner: true),
      );
      await tester.pumpWidget(
        _buildTestApp(repository: repo, productId: 'INV-OXY'),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Chưa cấu hình ngưỡng tồn; chưa thể xác định trạng thái tồn thấp/bình thường.',
        ),
        findsOneWidget,
      );
      expect(find.text('Đặt ngưỡng tồn'), findsOneWidget);
    });

    testWidgets('edit_threshold_pushes_policy_and_refreshes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? policyId;
      final repo = _FakeStockRepository((_) => _buildTylosinDetail());
      await tester.pumpWidget(
        _buildTestApp(
          repository: repo,
          onPolicyOpened: (id) => policyId = id,
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.detailLoadCount, 1);

      await tester.tap(find.text('Sửa ngưỡng'));
      await tester.pumpAndSettle();

      expect(policyId, 'INV-TYL');
      await tester.tap(find.text('Lưu ngưỡng'));
      await tester.pumpAndSettle();

      expect(repo.detailLoadCount, 2);
    });

    testWidgets('lot_sheet_near_expiry_390', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _FakeStockRepository((_) => _buildNobivacDetail());
      await tester.pumpWidget(
        _buildTestApp(repository: repo, productId: 'INV-NOB'),
      );
      await tester.pumpAndSettle();

      final lotRow = find.text('Lô NB2609');
      await tester.ensureVisible(lotRow);
      await tester.tap(lotRow);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Còn 13 ngày · vẫn đủ điều kiện bán theo chính sách hiện tại.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('provenance_sheet_no_reservation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _FakeStockRepository((_) => _buildTylosinDetail());
      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      final provRow = find.text('Nguồn và thời điểm cập nhật');
      await tester.ensureVisible(provRow);
      await tester.tap(provRow);
      await tester.pumpAndSettle();

      expect(find.text('Nhận hàng gần nhất'), findsOneWidget);
      expect(find.text('15/09/2026 · +14 lọ'), findsOneWidget);
      expect(find.text('Đang giữ'), findsNothing);
      // G5-7: trang chi tiết đã nối thẻ kho nên sheet nguồn có nút mở thẻ kho.
      expect(find.text('Xem thẻ kho và lịch sử'), findsOneWidget);
    });

    testWidgets('stock_detail_opens_card', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? opened;
      final repo = _FakeStockRepository((_) => _buildTylosinDetail());
      await tester.pumpWidget(
        _buildTestApp(repository: repo, onCardOpened: (uri) => opened = uri),
      );
      await tester.pumpAndSettle();

      final provRow = find.text('Nguồn và thời điểm cập nhật');
      await tester.ensureVisible(provRow);
      await tester.tap(provRow);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem thẻ kho và lịch sử'));
      await tester.pumpAndSettle();

      expect(opened, '/warehouse/reports/stock/INV-TYL?back=stock');
      expect(find.text('CARD:INV-TYL'), findsOneWidget);
    });

    testWidgets('detail_two_columns_1280', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeStockRepository((_) => _buildTylosinDetail());
      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      final heroLeft = tester.getTopLeft(find.text('Khả dụng')).dx;
      final lotsLeft = tester.getTopLeft(find.text('Lô và hạn dùng')).dx;
      expect(heroLeft, lessThan(lotsLeft));
    });

    testWidgets('detail_denied', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _FakeStockRepository(
        (_) => throw const AppException(InventoryErrorCode.permissionDenied),
      );
      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Chi tiết tồn kho'), findsOneWidget);
      expect(find.text('Bạn chưa có quyền xem tồn kho'), findsOneWidget);
    });

    testWidgets(
      'stock_detail_adjust_expired routes single lot vs multiple lots accurately',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // Một lô hết hạn -> nút banner mở ?lotId=L-TY2408
        String? navigatedUri;
        final singleRepo = _FakeStockRepository((_) => _buildTylosinDetail());
        await tester.pumpWidget(
          _buildTestApp(
            repository: singleRepo,
            onStocktakeOpened: (uri) => navigatedUri = uri,
          ),
        );
        await tester.pumpAndSettle();

        final adjustBannerBtn = find.text('Điều chỉnh lô hết hạn');
        expect(adjustBannerBtn, findsOneWidget);
        await tester.ensureVisible(adjustBannerBtn);
        await tester.tap(adjustBannerBtn);
        await tester.pumpAndSettle();
        expect(navigatedUri, '/warehouse/stocktakes/new?lotId=L-TY2408');

        // Hai lô hết hạn -> banner mở ?productId=..., sheet lô 2 mở ?lotId=L-EX2
        final multiExpiredDetail = StockDetail(
          asOf: DateTime(2026, 9, 17, 21, 30),
          warehouseName: 'Kho trung tâm',
          isOwner: true,
          productId: 'INV-MULTI',
          name: 'Amoxicillin LA',
          code: 'SP-000199',
          uom: 'lọ',
          isLotTracked: true,
          physical: 9,
          available: 0,
          expiredQuantity: 9,
          lots: const [
            StockLot(
              lotId: 'L-EX1',
              code: 'EX1',
              expiry: LotDate(year: 2025, month: 1, day: 10),
              physical: 4,
              isExpired: true,
              isNearExpiry: false,
              daysToExpiry: -200,
            ),
            StockLot(
              lotId: 'L-EX2',
              code: 'EX2',
              expiry: LotDate(year: 2025, month: 2, day: 20),
              physical: 5,
              isExpired: true,
              isNearExpiry: false,
              daysToExpiry: -160,
            ),
          ],
        );

        navigatedUri = null;
        final multiRepo = _FakeStockRepository((_) => multiExpiredDetail);
        await tester.pumpWidget(
          _buildTestApp(
            repository: multiRepo,
            productId: 'INV-MULTI',
            onStocktakeOpened: (uri) => navigatedUri = uri,
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Điều chỉnh lô hết hạn'));
        await tester.tap(find.text('Điều chỉnh lô hết hạn'));
        await tester.pumpAndSettle();
        expect(navigatedUri, '/warehouse/stocktakes/new?productId=INV-MULTI');

        await tester.tap(find.text('Mở kiểm kê $navigatedUri'));
        await tester.pumpAndSettle();

        navigatedUri = null;
        final secondLotRow = find.text('Lô EX2');
        await tester.ensureVisible(secondLotRow);
        await tester.tap(secondLotRow);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Điều chỉnh lô hết hạn').last);
        await tester.pumpAndSettle();
        expect(navigatedUri, '/warehouse/stocktakes/new?lotId=L-EX2');
      },
    );

    testWidgets('stock_detail_compare_row', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // StockDetailBody với onCompareSuppliers null -> ẩn
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StockDetailBody(detail: _buildTylosinDetail()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('So sánh nhà cung cấp'), findsNothing);

      // StockDetailBody có callback -> nằm trên 'Nguồn và thời điểm cập nhật'
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StockDetailBody(
                detail: _buildTylosinDetail(),
                onCompareSuppliers: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final compareFinder = find.text('So sánh nhà cung cấp');
      final provFinder = find.text('Nguồn và thời điểm cập nhật');
      expect(compareFinder, findsOneWidget);
      expect(
        tester.getTopLeft(compareFinder).dy,
        lessThan(tester.getTopLeft(provFinder).dy),
      );

      await tester.ensureVisible(compareFinder);
      await tester.tap(compareFinder);
      expect(tapped, isTrue);

      // StockDetailPage -> push /warehouse/stock/<id>/suppliers
      String? pushedCompare;
      final repo = _FakeStockRepository((_) => _buildTylosinDetail());
      await tester.pumpWidget(
        _buildTestApp(
          repository: repo,
          onCompareOpened: (uri) => pushedCompare = uri,
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('So sánh nhà cung cấp'));
      await tester.tap(find.text('So sánh nhà cung cấp'));
      await tester.pumpAndSettle();

      expect(pushedCompare, '/warehouse/stock/INV-TYL/suppliers');
      expect(find.text('COMPARE:INV-TYL'), findsOneWidget);
    });

    testWidgets('stock_cost_block_versions_link_owner_only', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final ownerRepo = _FakeStockRepository(
        (_) => _buildTylosinDetail(
          isOwner: true,
          cost: const StockCost(
            method: CostMethod.moving,
            officialUnitCost: 118500,
            movingAvgCost: 117940,
            ledgerValueVnd: 1651160,
          ),
        ),
      );
      await tester.pumpWidget(_buildTestApp(repository: ownerRepo));
      await tester.pumpAndSettle();
      expect(find.text('Lịch sử giá vốn'), findsOneWidget);

      final staffRepo = _FakeStockRepository(
        (_) => _buildTylosinDetail(isOwner: false, cost: null),
      );
      await tester.pumpWidget(_buildTestApp(repository: staffRepo));
      await tester.pumpAndSettle();
      expect(find.text('Lịch sử giá vốn'), findsNothing);
    });
  });
}
