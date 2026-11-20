// H20: PricingPickUnitPage tìm đơn vị bán qua catalog MeasurementUnitRepository và ProductPriceRepository.
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/measurement_unit_repository.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_price_repository.dart';
import 'package:erp/features/pricing/presentation/pages/pricing_pick_unit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

final class _MockMeasurementUnitRepository extends Fake implements MeasurementUnitRepository {
  _MockMeasurementUnitRepository({this.onListProductUnits});

  final Future<ProductUnitsDto> Function(String productId, {bool includeInactive})? onListProductUnits;
  String? lastProductId;
  bool? lastIncludeInactive;

  @override
  Future<ProductUnitsDto> listProductUnits(
    String productId, {
    bool includeInactive = false,
  }) async {
    lastProductId = productId;
    lastIncludeInactive = includeInactive;
    if (onListProductUnits != null) {
      return onListProductUnits!(productId, includeInactive: includeInactive);
    }
    return ProductUnitsDto(
      productId: productId,
      baseUnitName: 'Hộp',
      units: const [],
    );
  }
}

final class _MockProductPriceRepository extends Fake implements ProductPriceRepository {
  _MockProductPriceRepository({this.onGetPriceBandSnapshot});

  final Future<ProductPriceBandSnapshotDto> Function(
    List<ProductPriceBandSnapshotRequest> requests,
  )? onGetPriceBandSnapshot;

  List<ProductPriceBandSnapshotRequest>? lastRequests;

  @override
  Future<ProductPriceBandSnapshotDto> getPriceBandSnapshot(
    List<ProductPriceBandSnapshotRequest> requests,
  ) async {
    lastRequests = requests;
    if (onGetPriceBandSnapshot != null) {
      return onGetPriceBandSnapshot!(requests);
    }
    return const ProductPriceBandSnapshotDto(
      items: [],
    );
  }
}

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pump(
    WidgetTester tester, {
    required MeasurementUnitRepository unitRepo,
    required ProductPriceRepository priceRepo,
  }) async {
    getIt
      ..registerSingleton<MeasurementUnitRepository>(unitRepo)
      ..registerSingleton<ProductPriceRepository>(priceRepo);

    await tester.pumpWidget(
      const MaterialApp(
        home: PricingPickUnitPage(productId: 'prod-123'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tải danh sách đơn vị bán và hiển thị tên đơn vị (H20)', (tester) async {
    final unitRepo = _MockMeasurementUnitRepository(
      onListProductUnits: (productId, {includeInactive = false}) async {
        return const ProductUnitsDto(
          productId: 'prod-123',
          baseUnitName: 'Viên',
          units: [
            ProductUnitDto(
              id: 'unit-1',
              name: 'Hộp',
              conversionRateToBase: 10,
              isBaseUnit: false,
              isActive: true,
            ),
          ],
        );
      },
    );

    final priceRepo = _MockProductPriceRepository(
      onGetPriceBandSnapshot: (requests) async {
        return ProductPriceBandSnapshotDto(
          items: [
            ProductPriceBandSnapshotItemDto(
              productId: 'prod-123',
              productUnitId: 'unit-1',
              unitName: 'Hộp',
              currency: 'VND',
              listBeforeVat: 50000,
              listBeforeVatMissing: false,
              floorBeforeVat: 45000,
              floorBeforeVatMissing: false,
              floorBeforeVatHidden: false,
              isUnitActive: true,
              productBusinessStatus: ProductBusinessStatus.active,
              capturedAt: DateTime(2026, 1, 1),
            ),
          ],
        );
      },
    );

    await pump(tester, unitRepo: unitRepo, priceRepo: priceRepo);

    expect(unitRepo.lastProductId, 'prod-123');
    expect(priceRepo.lastRequests?.single.productUnitId, 'unit-1');
    expect(find.text('Hộp'), findsOneWidget);
  });

  testWidgets('lỗi tải đơn vị bán → hiển thị "Không tải được danh sách đơn vị bán." (H20)', (tester) async {
    final unitRepo = _MockMeasurementUnitRepository(
      onListProductUnits: (productId, {includeInactive = false}) async {
        throw const AppException('INTERNAL_ERROR');
      },
    );
    final priceRepo = _MockProductPriceRepository();

    await pump(tester, unitRepo: unitRepo, priceRepo: priceRepo);

    expect(find.text('Không tải được danh sách đơn vị bán.'), findsOneWidget);
  });
}
