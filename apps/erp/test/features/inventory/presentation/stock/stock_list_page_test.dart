import 'package:erp/core/di/injection.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/models/lot_date.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/data/stock/stock_repository.dart';
import 'package:erp/features/inventory/logic/stock/stale_watcher.dart';
import 'package:erp/features/inventory/presentation/stock/stock_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

class _FakeStockRepository implements StockRepository {
  StockOverview overview;
  Object? error;
  int loadCount = 0;
  int detailLoadCount = 0;
  final Map<String, Object> detailErrors = {};

  _FakeStockRepository(this.overview);

  @override
  Future<StockOverview> loadOverview() async {
    loadCount++;
    if (error != null) throw error!;
    return overview;
  }

  @override
  Future<StockDetail> loadDetail(String productId) async {
    detailLoadCount++;
    final detailError = detailErrors[productId];
    if (detailError != null) throw detailError;
    final item = overview.products.firstWhere(
      (p) => p.productId == productId,
      orElse: () => overview.products.first,
    );
    return StockDetail(
      asOf: overview.asOf,
      warehouseName: overview.warehouseName,
      isOwner: true,
      productId: item.productId,
      name: item.name,
      code: item.code,
      uom: item.uom,
      isLotTracked: item.isLotTracked,
      physical: item.physical,
      available: item.available,
      expiredQuantity: item.hasExpired ? (item.physical - item.available) : 0,
      threshold: item.threshold,
      target: item.threshold != null ? item.threshold! * 3 : null,
      lots: item.isLotTracked
          ? [
              StockLot(
                lotId: 'LOT-${item.productId}',
                code: 'L-${item.code}',
                expiry: const LotDate(year: 2027, month: 6, day: 15),
                physical: item.physical,
                isExpired: item.hasExpired,
                isNearExpiry: item.hasNearExpiry,
                daysToExpiry: item.hasNearExpiry ? 13 : 200,
              ),
            ]
          : const [],
    );
  }
}

StockOverview _buildFixtureOverview({List<StockOverviewItem>? products}) {
  return StockOverview(
    warehouseName: 'Kho trung tâm',
    asOf: DateTime(2026, 9, 17, 21, 30),
    products: products ??
        const [
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
            threshold: 30,
          ),
          StockOverviewItem(
            productId: 'INV-AMX',
            name: 'Amox 500',
            code: 'SP-000066',
            barcode: '8938500004068',
            uom: 'hộp',
            isLotTracked: false,
            physical: 48,
            available: 46,
            hasExpired: false,
            hasNearExpiry: false,
            threshold: 50,
          ),
          StockOverviewItem(
            productId: 'INV-ENRO',
            name: 'Enrofloxacin 10%',
            code: 'SP-000091',
            barcode: '8938500005096',
            uom: 'chai',
            isLotTracked: false,
            physical: 0,
            available: 0,
            hasExpired: false,
            hasNearExpiry: false,
            threshold: 10,
          ),
          StockOverviewItem(
            productId: 'INV-TYLO',
            name: 'Tylosin 20%',
            code: 'SP-000122',
            barcode: '8938500006123',
            uom: 'lọ',
            isLotTracked: true,
            physical: 14,
            available: 3,
            hasExpired: true,
            hasNearExpiry: false,
            threshold: 8,
          ),
          StockOverviewItem(
            productId: 'INV-OXY',
            name: 'Oxytetracycline LA',
            code: 'SP-000147',
            barcode: '8938500007144',
            uom: 'chai',
            isLotTracked: false,
            physical: 12,
            available: 11,
            hasExpired: false,
            hasNearExpiry: false,
            threshold: null,
          ),
        ],
  );
}

Widget _buildTestApp({
  required StockRepository repository,
  StaleWatcher? stale,
  ValueChanged<String>? onRoutePushed,
}) {
  if (getIt.isRegistered<StockRepository>()) {
    getIt.unregister<StockRepository>();
  }
  getIt.registerSingleton<StockRepository>(repository);

  final router = GoRouter(
    initialLocation: '/warehouse/stock',
    routes: [
      GoRoute(
        path: '/warehouse',
        builder: (_, _) => const Scaffold(body: Text('Hub Kho')),
      ),
      GoRoute(
        path: '/warehouse/stock',
        builder: (_, _) => StockListPage(stale: stale),
      ),
      GoRoute(
        path: '/warehouse/stock/:productId',
        builder: (_, state) {
          final id = state.pathParameters['productId']!;
          onRoutePushed?.call('/warehouse/stock/$id');
          return Scaffold(body: Text('Detail $id'));
        },
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
  );
}

void main() {
  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('StockListPage iPhone (390x844)', () {
    testWidgets('list_ready_390', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeStockRepository(_buildFixtureOverview());
      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      expect(
        find.text('Kho trung tâm · Dữ liệu đến 21:30, 17/09/2026'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Quét mã vạch'), findsNothing);

      // Dòng đầu là Enrofloxacin "0 chai" + "Hết hàng"
      final stockRows =
          tester.widgetList<VStockRow>(find.byType(VStockRow)).toList();
      expect(stockRows.length, 5);
      expect(stockRows.first.title, 'Enrofloxacin 10%');
      expect(stockRows.first.quantity, '0 chai');
      expect(
        find.descendant(
          of: find.byWidget(stockRows.first),
          matching: find.text('Hết hàng'),
        ),
        findsOneWidget,
      );

      // Oxy phụ đề "SP-000147 · Chưa có ngưỡng tồn", không badge
      final oxyRow = stockRows.last;
      expect(oxyRow.title, 'Oxytetracycline LA');
      expect(oxyRow.subtitle, 'SP-000147 · Chưa có ngưỡng tồn');
      expect(oxyRow.badge, isNull);
    });

    testWidgets('chip_tap_filters_390', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeStockRepository(_buildFixtureOverview());
      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      final nearChip = find.widgetWithText(VChip, 'Cận hạn');
      await tester.ensureVisible(nearChip);
      await tester.tap(nearChip);
      await tester.pumpAndSettle();

      final stockRows =
          tester.widgetList<VStockRow>(find.byType(VStockRow)).toList();
      expect(stockRows.length, 1);
      expect(stockRows.first.title, 'Nobivac DHPPi');
      expect(
        find.descendant(
          of: find.byWidget(stockRows.first),
          matching: find.text('Có lô cận hạn'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('empty_when_no_products', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeStockRepository(_buildFixtureOverview(products: const []));
      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Chưa có dữ liệu tồn kho'), findsOneWidget);
      expect(find.text('Không có dữ liệu trong kho hiện tại.'), findsOneWidget);
    });

    testWidgets('filter_empty_clear_resets', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeStockRepository(_buildFixtureOverview());
      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(VSearchBar), 'khongtontai123');
      await tester.pumpAndSettle();

      expect(find.text('Không có kết quả phù hợp'), findsOneWidget);
      expect(
        find.text('Thử tên, mã sản phẩm hoặc chọn bộ lọc khác.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Xóa tìm kiếm và bộ lọc'));
      await tester.pumpAndSettle();

      expect(find.byType(VStockRow), findsNWidgets(5));
    });

    testWidgets('stale_banner_refresh', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var currentTime = DateTime(2026, 9, 17, 21, 30);
      final repo = _FakeStockRepository(_buildFixtureOverview());
      await tester.pumpWidget(
        _buildTestApp(
          repository: repo,
          stale: StaleWatcher(now: () => currentTime),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dữ liệu có thể đã cũ'), findsNothing);

      // Advance > 5 minutes and trigger AppLifecycleState.resumed
      currentTime = DateTime(2026, 9, 17, 21, 36);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('Dữ liệu có thể đã cũ'), findsOneWidget);
      expect(find.text('Hãy làm mới trước khi sử dụng.'), findsOneWidget);

      // Update overview.asOf to currentTime on refresh
      repo.overview = StockOverview(
        warehouseName: 'Kho trung tâm',
        asOf: currentTime,
        products: repo.overview.products,
      );

      await tester.tap(find.text('Làm mới'));
      await tester.pumpAndSettle();

      expect(find.text('Dữ liệu có thể đã cũ'), findsNothing);
      expect(repo.loadCount, 2);
    });

    testWidgets('denied_390', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeStockRepository(_buildFixtureOverview())
        ..error = const AppException(InventoryErrorCode.permissionDenied);
      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Bạn chưa có quyền xem tồn kho'), findsOneWidget);
      expect(
        find.text(
          'Bạn chưa được cấp quyền xem tồn kho. Liên hệ chủ cửa hàng nếu cần.',
        ),
        findsOneWidget,
      );
      expect(find.text('Về Kho'), findsOneWidget);
    });

    testWidgets('row_tap_opens_detail_route', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? pushedRoute;
      final repo = _FakeStockRepository(_buildFixtureOverview());
      await tester.pumpWidget(
        _buildTestApp(
          repository: repo,
          onRoutePushed: (route) => pushedRoute = route,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Amox 500'));
      await tester.pumpAndSettle();

      expect(pushedRoute, '/warehouse/stock/INV-AMX');
      expect(find.text('Detail INV-AMX'), findsOneWidget);
    });
  });

  group('StockListPage Web (1280x800)', () {
    testWidgets('list_detail_ready_1280', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeStockRepository(_buildFixtureOverview());
      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      // 4 tiêu đề cột, không "Đã giữ"
      expect(find.text('SẢN PHẨM'), findsOneWidget);
      expect(find.text('KHẢ DỤNG'), findsOneWidget);
      expect(find.text('TỒN VẬT LÝ'), findsOneWidget);
      expect(find.text('CHỈ BÁO'), findsOneWidget);
      expect(find.text('ĐÃ GIỮ'), findsNothing);

      // Cột phải hiện thẻ số của dòng đầu "Enrofloxacin 10%"
      expect(
        find.text('Ngưỡng 10 · Mục tiêu 30 chai'),
        findsOneWidget,
      );
    });

    testWidgets('row_tap_changes_aside_not_route_1280', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? pushedRoute;
      final repo = _FakeStockRepository(_buildFixtureOverview());
      await tester.pumpWidget(
        _buildTestApp(
          repository: repo,
          onRoutePushed: (route) => pushedRoute = route,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Amox 500'));
      await tester.pumpAndSettle();

      expect(pushedRoute, isNull);
      expect(
        find.text('Ngưỡng 50 · Mục tiêu 150 hộp'),
        findsOneWidget,
      );
    });

    testWidgets('selected_falls_back_to_first_visible_1280', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeStockRepository(_buildFixtureOverview());
      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();

      // Chọn Amox 500
      await tester.tap(find.text('Amox 500'));
      await tester.pumpAndSettle();
      expect(find.text('Ngưỡng 50 · Mục tiêu 150 hộp'), findsOneWidget);

      // Lọc "Hết hạn" => cột phải là Tylosin
      final expiredChip = find.widgetWithText(VChip, 'Hết hạn');
      await tester.ensureVisible(expiredChip);
      await tester.tap(expiredChip);
      await tester.pumpAndSettle();

      expect(find.text('Ngưỡng 8 · Mục tiêu 24 lọ'), findsOneWidget);
    });

    testWidgets('aside_error_shows_retry_1280', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeStockRepository(_buildFixtureOverview());
      repo.detailErrors['INV-AMX'] = Exception('network');
      await tester.pumpWidget(_buildTestApp(repository: repo));
      await tester.pumpAndSettle();
      expect(find.text('Ngưỡng 10 · Mục tiêu 30 chai'), findsOneWidget);

      await tester.tap(find.text('Amox 500'));
      await tester.pumpAndSettle();

      // Không còn chi tiết của Enrofloxacin (dòng cũ) ở cột phải.
      expect(find.text('Ngưỡng 10 · Mục tiêu 30 chai'), findsNothing);
      expect(find.text('Không thể tải chi tiết tồn kho'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('refresh_reloads_aside_1280', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var currentTime = DateTime(2026, 9, 17, 21, 30);
      final repo = _FakeStockRepository(_buildFixtureOverview());
      await tester.pumpWidget(
        _buildTestApp(
          repository: repo,
          stale: StaleWatcher(now: () => currentTime),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Amox 500'));
      await tester.pumpAndSettle();
      expect(find.text('Ngưỡng 50 · Mục tiêu 150 hộp'), findsOneWidget);

      currentTime = DateTime(2026, 9, 17, 21, 36);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Dữ liệu có thể đã cũ'), findsOneWidget);

      // Máy chủ trả số mới cho Amox (vẫn tồn thấp, vẫn hiện).
      repo.overview = StockOverview(
        warehouseName: 'Kho trung tâm',
        asOf: currentTime,
        products: [
          for (final p in repo.overview.products)
            p.productId == 'INV-AMX'
                ? StockOverviewItem(
                    productId: p.productId,
                    name: p.name,
                    code: p.code,
                    barcode: p.barcode,
                    uom: p.uom,
                    isLotTracked: p.isLotTracked,
                    physical: 42,
                    available: 40,
                    threshold: p.threshold,
                  )
                : p,
        ],
      );

      await tester.tap(find.text('Làm mới'));
      await tester.pumpAndSettle();

      expect(find.text('40 hộp'), findsWidgets);
      expect(find.text('46 hộp'), findsNothing);
    });
  });
}
