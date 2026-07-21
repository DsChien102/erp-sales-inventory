import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

final class _RecordingPriceBandGateway implements IProductPriceBandGateway {
  int callCount = 0;
  int? listBeforeVat;
  int? floorBeforeVat;
  PriceBandSourceType? sourceType;
  double? listMarkupRatio;
  double? floorMarkupRatio;
  String? storePriceRuleId;

  @override
  Future<void> setProductUnitPriceBand({
    required String tenantId,
    required String productId,
    required String productUnitId,
    required int? listBeforeVat,
    required int? listAfterVat,
    required PriceBandSourceType sourceType,
    int? floorBeforeVat,
    int? floorAfterVat,
    double? listMarkupRatio,
    double? floorMarkupRatio,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    ProductPriceBandStatus? status,
    String? storePriceRuleId,
  }) async {
    callCount += 1;
    this.listBeforeVat = listBeforeVat;
    this.floorBeforeVat = floorBeforeVat;
    this.sourceType = sourceType;
    this.listMarkupRatio = listMarkupRatio;
    this.floorMarkupRatio = floorMarkupRatio;
    this.storePriceRuleId = storePriceRuleId;
  }

  @override
  Future<ProductUnitPriceBandsDto> listProductUnitPriceBands({
    required String tenantId,
    required String productId,
  }) => throw UnimplementedError();

  @override
  Future<ProductPriceBandSnapshotDto> getPriceBandSnapshot({
    required String tenantId,
    required List<ProductPriceBandSnapshotRequest> items,
  }) => throw UnimplementedError();
}

final class _UnitGateway implements ICatalogUnitGateway {
  const _UnitGateway(this.unit);

  final ProductUnitDto unit;

  @override
  Future<ProductUnitsDto> listProductUnits({
    required ListProductUnitsQuery query,
  }) async => ProductUnitsDto(
    productId: query.productId,
    baseUnitName: 'Lọ',
    units: [unit],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ReadGateway implements ICatalogReadGateway {
  const _ReadGateway(this.basePriceAmount);

  final double? basePriceAmount;

  @override
  Future<ProductControlCenterReadModel?> loadControlCenter({
    required String tenantId,
    required String productId,
  }) async => ProductControlCenterReadModel(
    productId: productId,
    name: 'Thuốc thử',
    businessStatus: ProductBusinessStatus.active,
    facts: ProductReadinessFacts(
      productId: productId,
      productName: 'Thuốc thử',
      hasBaseUnit: true,
      hasImages: true,
      hasStock: true,
      hasBasePrice: basePriceAmount != null,
      hasPriceBand: true,
      hasRequiredCustomFields: true,
    ),
    basePriceAmount: basePriceAmount,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ReadinessPort implements IProductReadinessReadPort {
  @override
  Future<ProductReadinessFacts?> loadFacts({
    required String tenantId,
    required String productId,
  }) async => ProductReadinessFacts(
    productId: productId,
    productName: 'Thuốc thử',
    hasBaseUnit: true,
    hasImages: true,
    hasStock: true,
    hasBasePrice: true,
    hasPriceBand: true,
    hasRequiredCustomFields: true,
  );
}

void main() {
  const conversionUnit = ProductUnitDto(
    id: 'unit-box',
    name: 'Hộp',
    conversionRateToBase: 10,
    isBaseUnit: false,
    isActive: true,
  );

  SetProductUnitPriceBandCommandHandler createHandler(
    _RecordingPriceBandGateway gateway, {
    double? basePriceAmount = 5000,
  }) => SetProductUnitPriceBandCommandHandler(
    priceBandGateway: gateway,
    readinessReadPort: _ReadinessPort(),
    unitGateway: const _UnitGateway(conversionUnit),
    catalogReadGateway: _ReadGateway(basePriceAmount),
  );

  test('custom config calculates from converted base price and saves ratios', () async {
    final gateway = _RecordingPriceBandGateway();

    final result = await createHandler(gateway).handle(
      SetProductUnitPriceBandCommand(
        tenantId: 'tenant-1',
        productId: 'product-1',
        productUnitId: 'unit-box',
        sourceType: PriceBandSourceType.customConfig,
        listMarkupRatio: 0.35,
        floorMarkupRatio: 0.15,
      ),
    );

    expect(result.listBeforeVat, 67500);
    expect(result.floorBeforeVat, 57500);
    expect(result.listAfterVat, 67500);
    expect(result.floorAfterVat, 57500);
    expect(gateway.sourceType, PriceBandSourceType.customConfig);
    expect(gateway.listMarkupRatio, 0.35);
    expect(gateway.floorMarkupRatio, 0.15);
    expect(gateway.storePriceRuleId, isNull);
  });

  test('manual saves absolute prices without ratios or store rule', () async {
    final gateway = _RecordingPriceBandGateway();

    await createHandler(gateway).handle(
      SetProductUnitPriceBandCommand(
        tenantId: 'tenant-1',
        productId: 'product-1',
        productUnitId: 'unit-box',
        listBeforeVat: 700000,
        listAfterVat: 700000,
        floorBeforeVat: 600000,
        floorAfterVat: 600000,
        sourceType: PriceBandSourceType.manual,
      ),
    );

    expect(gateway.listBeforeVat, 700000);
    expect(gateway.floorBeforeVat, 600000);
    expect(gateway.listMarkupRatio, isNull);
    expect(gateway.floorMarkupRatio, isNull);
    expect(gateway.storePriceRuleId, isNull);
  });

  test('custom config preserves a missing floor ratio as null', () async {
    final gateway = _RecordingPriceBandGateway();

    final result = await createHandler(gateway).handle(
      SetProductUnitPriceBandCommand(
        tenantId: 'tenant-1',
        productId: 'product-1',
        productUnitId: 'unit-box',
        sourceType: PriceBandSourceType.customConfig,
        listMarkupRatio: 0.35,
      ),
    );

    expect(result.floorBeforeVat, isNull);
    expect(gateway.floorMarkupRatio, isNull);
  });

  test('custom config saves pending ratios without a base price', () async {
    final gateway = _RecordingPriceBandGateway();

    final result =
        await createHandler(
          gateway,
          basePriceAmount: null,
        ).handle(
          SetProductUnitPriceBandCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            productUnitId: 'unit-box',
            sourceType: PriceBandSourceType.customConfig,
            listMarkupRatio: 0.35,
            floorMarkupRatio: 0.15,
          ),
        );

    expect(result.listBeforeVat, isNull);
    expect(result.floorBeforeVat, isNull);
    expect(result.listAfterVat, isNull);
    expect(result.floorAfterVat, isNull);
    expect(gateway.listBeforeVat, isNull);
    expect(gateway.floorBeforeVat, isNull);
    expect(gateway.sourceType, PriceBandSourceType.customConfig);
    expect(gateway.listMarkupRatio, 0.35);
    expect(gateway.floorMarkupRatio, 0.15);
  });

  group('source field matrix validation', () {
    final validator = SetProductUnitPriceBandCommandValidator();

    test('rejects ruleBased because it has a dedicated command', () {
      expect(
        () => validator.validate(
          SetProductUnitPriceBandCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            sourceType: PriceBandSourceType.ruleBased,
            storePriceRuleId: 'rule-1',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects custom config without list ratio', () {
      expect(
        () => validator.validate(
          SetProductUnitPriceBandCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            sourceType: PriceBandSourceType.customConfig,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects manual with formula fields', () {
      expect(
        () => validator.validate(
          SetProductUnitPriceBandCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            listBeforeVat: 70000,
            listAfterVat: 70000,
            sourceType: PriceBandSourceType.manual,
            listMarkupRatio: 0.35,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
