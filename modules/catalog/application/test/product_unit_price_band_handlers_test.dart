import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';

class _RecordingProductPriceBandGateway implements IProductPriceBandGateway {
  ProductUnitPriceBandsDto? lastListed;
  String? lastSetProductUnitId;
  int? lastListBeforeVat;
  int? lastFloorBeforeVat;

  @override
  Future<ProductUnitPriceBandsDto> listProductUnitPriceBands({
    required String tenantId,
    required String productId,
  }) async {
    final dto = ProductUnitPriceBandsDto(
      productId: productId,
      baseUnitName: 'Lọ',
      rows: const [
        ProductUnitPriceBandRowDto(
          productUnitId: 'unit-lo',
          unitName: 'Lọ',
          isBaseUnit: true,
          isActive: true,
          isMissing: true,
        ),
        ProductUnitPriceBandRowDto(
          productUnitId: 'unit-hop',
          unitName: 'Hộp',
          isBaseUnit: false,
          isActive: true,
          isMissing: true,
        ),
      ],
    );
    lastListed = dto;
    return dto;
  }

  @override
  Future<ProductPriceBandSnapshotDto> getPriceBandSnapshot({
    required String tenantId,
    required List<ProductPriceBandSnapshotRequest> items,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> setProductUnitPriceBand({
    required String tenantId,
    required String productId,
    required String productUnitId,
    required int? listBeforeVat,
    required int? listAfterVat,
    int? floorBeforeVat,
    required PriceBandSourceType sourceType,
    int? floorAfterVat,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    ProductPriceBandStatus? status,
    String? storePriceRuleId,
    double? listMarkupRatio,
    double? floorMarkupRatio,
  }) async {
    lastSetProductUnitId = productUnitId;
    lastListBeforeVat = listBeforeVat;
    lastFloorBeforeVat = floorBeforeVat;
  }
}

class _FakeCatalogUnitGateway implements ICatalogUnitGateway {
  _FakeCatalogUnitGateway({
    this.units = const [],
  }) : baseUnitName = 'Lọ';

  final List<ProductUnitDto> units;
  final String baseUnitName;

  @override
  Future<List<TenantMeasurementUnitDto>> listTenantUnits({
    required String tenantId,
    String? keyword,
    required int limit,
  }) async {
    return const [];
  }

  @override
  Future<bool> isDuplicateUnitName({
    required String tenantId,
    required String name,
  }) async {
    return false;
  }

  @override
  Future<SetProductBaseUnitResult> setProductBaseUnit({
    required SetProductBaseUnitCommand command,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ProductUnitsDto> listProductUnits({
    required ListProductUnitsQuery query,
  }) async {
    return ProductUnitsDto(
      productId: query.productId,
      baseUnitName: baseUnitName,
      units: units,
    );
  }

  @override
  Future<ProductUnitMutationResult> addConversionUnit({
    required AddProductConversionUnitCommand command,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ProductUnitMutationResult> deactivateConversionUnit({
    required DeactivateProductConversionUnitCommand command,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ProductUnitMutationResult> reactivateConversionUnit({
    required ReactivateProductConversionUnitCommand command,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteConversionUnit({
    required DeleteProductConversionUnitCommand command,
  }) async {
    throw UnimplementedError();
  }
}

class _FakeCatalogReadGateway implements ICatalogReadGateway {
  _FakeCatalogReadGateway({this.basePriceAmount});

  final double? basePriceAmount;

  @override
  Future<ProductSearchResultDto> search({
    required String tenantId,
    required ProductSearchCriteria criteria,
    required int limit,
    required int offset,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ProductListItemDto?> findByBarcode({
    required String tenantId,
    required String barcode,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ProductControlCenterReadModel?> loadControlCenter({
    required String tenantId,
    required String productId,
  }) async {
    return ProductControlCenterReadModel(
      productId: productId,
      name: 'Test',
      businessStatus: ProductBusinessStatus.active,
      facts: ProductReadinessFacts(
        productId: productId,
        productName: 'Test',
        hasBaseUnit: true,
        hasImages: true,
        hasStock: true,
        hasBasePrice: basePriceAmount != null,
        hasPriceBand: false,
        hasRequiredCustomFields: true,
      ),
      basePriceAmount: basePriceAmount,
    );
  }

  @override
  Future<List<CustomFieldFilterOptionDto>> listCustomFieldFilterOptions({
    required String tenantId,
    required int maxOptionsPerField,
  }) async {
    throw UnimplementedError();
  }
}

class _FakeProductReadinessReadPort implements IProductReadinessReadPort {
  _FakeProductReadinessReadPort({
    bool Function(int loadCount)? hasPriceBandForLoad,
  }) : hasBaseUnit = true,
       _hasPriceBandForLoad = hasPriceBandForLoad ?? ((_) => false);

  final bool hasBaseUnit;
  final bool Function(int loadCount) _hasPriceBandForLoad;
  int loadCount = 0;

  @override
  Future<ProductReadinessFacts?> loadFacts({
    required String tenantId,
    required String productId,
  }) async {
    loadCount += 1;
    return ProductReadinessFacts(
      productId: productId,
      productName: 'Test product',
      hasBaseUnit: hasBaseUnit,
      hasImages: true,
      hasStock: true,
      hasBasePrice: true,
      hasPriceBand: _hasPriceBandForLoad(loadCount),
      hasRequiredCustomFields: true,
    );
  }
}

void main() {
  group('Product unit price band handlers', () {
    const baseUnit = ProductUnitDto(
      id: 'unit-lo',
      name: 'Lọ',
      conversionRateToBase: 1,
      isBaseUnit: true,
      isActive: true,
    );

    const conversionUnit = ProductUnitDto(
      id: 'unit-hop',
      name: 'Hộp',
      conversionRateToBase: 10,
      isBaseUnit: false,
      isActive: true,
    );

    const inactiveUnit = ProductUnitDto(
      id: 'unit-thung',
      name: 'Thùng',
      conversionRateToBase: 100,
      isBaseUnit: false,
      isActive: false,
    );

    test('scn_e06_u03_fr01_01 sets price band and refreshes readiness', () async {
      final gateway = _RecordingProductPriceBandGateway();
      final readiness = _FakeProductReadinessReadPort(
        hasPriceBandForLoad: (loadCount) => loadCount > 1,
      );
      final handler = SetProductUnitPriceBandCommandHandler(
        priceBandGateway: gateway,
        readinessReadPort: readiness,
        unitGateway: _FakeCatalogUnitGateway(units: [baseUnit]),
        catalogReadGateway: _FakeCatalogReadGateway(basePriceAmount: 25000),
      );

      final result = await handler.handle(
        SetProductUnitPriceBandCommand(
          tenantId: 'tenant-1',
          productId: 'product-4',
          listBeforeVat: 37500,
          listAfterVat: 37500,
          floorBeforeVat: 31250,
        ),
      );

      expect(result.listBeforeVat, 37500);
      expect(result.productUnitId, 'unit-lo');
      expect(gateway.lastSetProductUnitId, 'unit-lo');
      expect(result.readinessSummary.blockers, isEmpty);
    });

    test('scn_e06_u03_fr01_02 validator rejects floor greater than list', () async {
      final validator = SetProductUnitPriceBandCommandValidator();
      await expectLater(
        validator.validate(
          SetProductUnitPriceBandCommand(
            tenantId: 'tenant-1',
            productId: 'product-4',
            listBeforeVat: 100000,
            listAfterVat: 100000,
            floorBeforeVat: 110000,
          ),
        ),
        throwsA(isA<FloorPriceGreaterThanListPriceException>()),
      );
    });

    test('scn_e06_u03_fr01_03 lists price bands per active unit', () async {
      final gateway = _RecordingProductPriceBandGateway();
      final handler = ListProductUnitPriceBandsQueryHandler(
        priceBandGateway: gateway,
      );

      final result = await handler.handle(
        ListProductUnitPriceBandsQuery(
          tenantId: 'tenant-1',
          productId: 'product-9',
        ),
      );

      expect(result.rows, hasLength(2));
      expect(gateway.lastListed?.productId, 'product-9');
    });

    test('scn_e06_u03_fr01_04 rejects inactive unit', () async {
      final handler = SetProductUnitPriceBandCommandHandler(
        priceBandGateway: _RecordingProductPriceBandGateway(),
        readinessReadPort: _FakeProductReadinessReadPort(),
        unitGateway: _FakeCatalogUnitGateway(
          units: [baseUnit, inactiveUnit],
        ),
        catalogReadGateway: _FakeCatalogReadGateway(basePriceAmount: 80000),
      );

      await expectLater(
        handler.handle(
          SetProductUnitPriceBandCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            productUnitId: 'unit-thung',
            listBeforeVat: 1000000,
            listAfterVat: 1000000,
            floorBeforeVat: 900000,
          ),
        ),
        throwsA(isA<InactiveProductUnitException>()),
      );
    });

    test('scn_e06_u03_fr02_01 requires acknowledgment for warnings', () async {
      final handler = SetProductUnitPriceBandCommandHandler(
        priceBandGateway: _RecordingProductPriceBandGateway(),
        readinessReadPort: _FakeProductReadinessReadPort(),
        unitGateway: _FakeCatalogUnitGateway(units: [baseUnit]),
        catalogReadGateway: _FakeCatalogReadGateway(basePriceAmount: 100000),
      );

      await expectLater(
        handler.handle(
          SetProductUnitPriceBandCommand(
            tenantId: 'tenant-1',
            productId: 'product-11',
            listBeforeVat: 95000,
            listAfterVat: 95000,
            floorBeforeVat: 90000,
          ),
        ),
        throwsA(isA<PriceBandWarningsRequireAcknowledgmentException>()),
      );
    });

    test('scn_e06_u03_fr02_02 saves with warnings when confirmed', () async {
      final gateway = _RecordingProductPriceBandGateway();
      final handler = SetProductUnitPriceBandCommandHandler(
        priceBandGateway: gateway,
        readinessReadPort: _FakeProductReadinessReadPort(),
        unitGateway: _FakeCatalogUnitGateway(units: [baseUnit]),
        catalogReadGateway: _FakeCatalogReadGateway(basePriceAmount: 100000),
      );

      final result = await handler.handle(
        SetProductUnitPriceBandCommand(
          tenantId: 'tenant-1',
          productId: 'product-11',
          listBeforeVat: 95000,
          listAfterVat: 95000,
          floorBeforeVat: 90000,
          confirmAcknowledgeWarnings: true,
        ),
      );

      expect(result.warnings, isNotEmpty);
      expect(gateway.lastListBeforeVat, 95000);
    });

    test('scn_e06_u03_fr02_03 warns when conversion rate invalid', () async {
      const badConversionUnit = ProductUnitDto(
        id: 'unit-hop',
        name: 'Hộp',
        conversionRateToBase: 0,
        isBaseUnit: false,
        isActive: true,
      );

      final handler = SetProductUnitPriceBandCommandHandler(
        priceBandGateway: _RecordingProductPriceBandGateway(),
        readinessReadPort: _FakeProductReadinessReadPort(),
        unitGateway: _FakeCatalogUnitGateway(units: [baseUnit, badConversionUnit]),
        catalogReadGateway: _FakeCatalogReadGateway(basePriceAmount: 100000),
      );

      final result = await handler.handle(
        SetProductUnitPriceBandCommand(
          tenantId: 'tenant-1',
          productId: 'product-11',
          productUnitId: 'unit-hop',
          listBeforeVat: 950000,
          listAfterVat: 950000,
          floorBeforeVat: 900000,
          confirmAcknowledgeWarnings: true,
        ),
      );

      expect(
        result.warnings.any((w) => w.code == 'cannot_compare_base_price'),
        isTrue,
      );
    });

    test('scn_e06_u03_fr03_01 clears missing price band blocker', () async {
      final readiness = _FakeProductReadinessReadPort(
        hasPriceBandForLoad: (loadCount) => loadCount > 1,
      );
      final handler = SetProductUnitPriceBandCommandHandler(
        priceBandGateway: _RecordingProductPriceBandGateway(),
        readinessReadPort: readiness,
        unitGateway: _FakeCatalogUnitGateway(units: [baseUnit]),
        catalogReadGateway: _FakeCatalogReadGateway(basePriceAmount: 25000),
      );

      final result = await handler.handle(
        SetProductUnitPriceBandCommand(
          tenantId: 'tenant-1',
          productId: 'product-4',
          listBeforeVat: 37500,
          listAfterVat: 37500,
          floorBeforeVat: 31250,
        ),
      );

      expect(
        result.readinessSummary.blockers.any(
          (b) => b.code == ReadinessBlockerCode.missingPriceBand,
        ),
        isFalse,
      );
    });

    test('scn_e06_u03_fr03_02 keeps blocker when another unit lacks band', () async {
      final readiness = _FakeProductReadinessReadPort();
      final handler = SetProductUnitPriceBandCommandHandler(
        priceBandGateway: _RecordingProductPriceBandGateway(),
        readinessReadPort: readiness,
        unitGateway: _FakeCatalogUnitGateway(
          units: [baseUnit, conversionUnit],
        ),
        catalogReadGateway: _FakeCatalogReadGateway(basePriceAmount: 10000),
      );

      final result = await handler.handle(
        SetProductUnitPriceBandCommand(
          tenantId: 'tenant-1',
          productId: 'product-9',
          productUnitId: 'unit-lo',
          listBeforeVat: 15000,
          listAfterVat: 15000,
          floorBeforeVat: 12000,
        ),
      );

      expect(
        result.readinessSummary.blockers.any(
          (b) => b.code == ReadinessBlockerCode.missingPriceBand,
        ),
        isTrue,
      );
    });
  });
}
