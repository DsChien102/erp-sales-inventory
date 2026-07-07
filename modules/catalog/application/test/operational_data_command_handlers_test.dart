import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

class _RecordingProductCommandGateway implements IProductCommandGateway {
  String? lastProductId;
  String? lastTenantId;
  ProductStockProfile? lastStockProfile;
  ProductBasePriceProfile? lastPriceProfile;
  ProductUnitPriceBand? lastPriceBand;
  String? lastCurrency;

  @override
  Future<String> create({
    required Product product,
    required String idempotencyKey,
  }) async {
    return 'id';
  }

  @override
  Future<void> setInitialStock({
    required String productId,
    required String tenantId,
    required ProductStockProfile profile,
  }) async {
    lastProductId = productId;
    lastTenantId = tenantId;
    lastStockProfile = profile;
  }

  @override
  Future<void> setManualBasePrice({
    required String productId,
    required String tenantId,
    required ProductBasePriceProfile profile,
    String currency = 'VND',
  }) async {
    lastProductId = productId;
    lastTenantId = tenantId;
    lastPriceProfile = profile;
    lastCurrency = currency;
  }

  @override
  Future<void> setInitialPriceBand({
    required String productId,
    required String tenantId,
    required ProductUnitPriceBand priceBand,
  }) async {
    lastProductId = productId;
    lastTenantId = tenantId;
    lastPriceBand = priceBand;
  }

  @override
  Future<UpdateProductProfileResult> updateProductProfile(
    UpdateProductProfileCommand command,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<UpdateProductImagesResult> updateProductImages(
    UpdateProductImagesCommand command,
  ) async {
    throw UnimplementedError();
  }
}

class _FakeProductReadinessReadPort implements IProductReadinessReadPort {
  _FakeProductReadinessReadPort({
    required this.hasBaseUnit,
    this.hasStock = false,
    this.hasBasePrice = false,
    this.hasPriceBand = false,
  });

  final bool hasBaseUnit;
  final bool hasStock;
  final bool hasBasePrice;
  final bool hasPriceBand;
  String? lastTenantId;
  String? lastProductId;

  @override
  Future<ProductReadinessFacts?> loadFacts({
    required String tenantId,
    required String productId,
  }) async {
    lastTenantId = tenantId;
    lastProductId = productId;
    return ProductReadinessFacts(
      productId: productId,
      productName: 'Thuốc A',
      hasBaseUnit: hasBaseUnit,
      hasImages: true,
      hasStock: hasStock,
      hasBasePrice: hasBasePrice,
      hasPriceBand: hasPriceBand,
      hasRequiredCustomFields: true,
    );
  }
}

class _RecordingCatalogUnitGateway implements ICatalogUnitGateway {
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
      baseUnitName: 'Lọ',
      units: const [],
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
}

void main() {
  group('SetInitialStockCommandHandler & Validator', () {
    test('valid basic stock sets initial stock on gateway', () async {
      final gateway = _RecordingProductCommandGateway();
      final readinessPort = _FakeProductReadinessReadPort(hasBaseUnit: true);
      final handler = SetInitialStockCommandHandler(
        commandGateway: gateway,
        readinessReadPort: readinessPort,
        unitGateway: _RecordingCatalogUnitGateway(),
      );
      final validator = SetInitialStockCommandValidator();

      final command = SetInitialStockCommand(
        tenantId: 'tenant-1',
        productId: 'prod-1',
        quantity: 100.0,
      );

      await validator.validate(command);
      final result = await handler.handle(command);

      expect(gateway.lastProductId, 'prod-1');
      expect(gateway.lastTenantId, 'tenant-1');
      expect(gateway.lastStockProfile?.initialStock, 100.0);
      expect(readinessPort.lastProductId, 'prod-1');
      expect(result.productId, 'prod-1');
      expect(result.quantity, 100.0);
      expect(result.unitName, 'Lọ');
      expect(result.readinessSummary, isNotNull);
    });

    test('scn_e05_u02_fr01_01 set initial stock returns result with readiness', () async {
      final gateway = _RecordingProductCommandGateway();
      final readinessPort = _FakeProductReadinessReadPort(
        hasBaseUnit: true,
        hasStock: true,
      );
      final handler = SetInitialStockCommandHandler(
        commandGateway: gateway,
        readinessReadPort: readinessPort,
        unitGateway: _RecordingCatalogUnitGateway(),
      );

      final result = await handler.handle(
        SetInitialStockCommand(
          tenantId: 'tenant-1',
          productId: 'prod-1',
          quantity: 50.0,
        ),
      );

      expect(result.quantity, 50.0);
      expect(result.readinessSummary.status, ReadinessStatus.incomplete);
    });

    test('negative quantity throws ValidationException', () async {
      final validator = SetInitialStockCommandValidator();
      final command = SetInitialStockCommand(
        tenantId: 'tenant-1',
        productId: 'prod-1',
        quantity: -5.0,
      );

      expect(
        () => validator.validate(command),
        throwsA(isA<ValidationException>()),
      );
    });

    test('non basic mode throws NotBasicStockModeException', () async {
      final validator = SetInitialStockCommandValidator();
      final command = SetInitialStockCommand(
        tenantId: 'tenant-1',
        productId: 'prod-1',
        quantity: 10.0,
        mode: 'advanced',
      );

      expect(
        () => validator.validate(command),
        throwsA(isA<NotBasicStockModeException>()),
      );
    });

    test('scn_e04_u01_fr02_01 missing base unit blocks initial stock', () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = SetInitialStockCommandHandler(
        commandGateway: gateway,
        readinessReadPort: _FakeProductReadinessReadPort(hasBaseUnit: false),
        unitGateway: _RecordingCatalogUnitGateway(),
      );

      await expectLater(
        handler.handle(
          SetInitialStockCommand(
            tenantId: 'tenant-1',
            productId: 'prod-1',
            quantity: 10.0,
          ),
        ),
        throwsA(isA<MissingBaseUnitException>()),
      );
      expect(gateway.lastStockProfile, isNull);
    });
  });

  group('SetManualBasePriceCommandHandler & Validator', () {
    test('scn_e06_u01_fr02_01 set manual base price returns result with readiness', () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = SetManualBasePriceCommandHandler(
        commandGateway: gateway,
        readinessReadPort: _FakeProductReadinessReadPort(
          hasBaseUnit: true,
          hasBasePrice: true,
          hasStock: true,
          hasPriceBand: true,
        ),
        unitGateway: _RecordingCatalogUnitGateway(),
      );
      final validator = SetManualBasePriceCommandValidator();

      final command = SetManualBasePriceCommand(
        tenantId: 'tenant-1',
        productId: 'prod-1',
        basePrice: 50000.0,
        currency: 'VND',
      );

      await validator.validate(command);
      final result = await handler.handle(command);

      expect(gateway.lastProductId, 'prod-1');
      expect(gateway.lastTenantId, 'tenant-1');
      expect(gateway.lastPriceProfile?.basePrice?.amount, 50000.0);
      expect(gateway.lastCurrency, 'VND');
      expect(result.productId, 'prod-1');
      expect(result.basePrice, 50000.0);
      expect(result.currency, 'VND');
      expect(result.unitName, 'Lọ');
      expect(result.readinessSummary.blockers, isEmpty);
    });

    test('negative base price throws ValidationException', () async {
      final validator = SetManualBasePriceCommandValidator();
      final command = SetManualBasePriceCommand(
        tenantId: 'tenant-1',
        productId: 'prod-1',
        basePrice: -100.0,
      );

      expect(
        () => validator.validate(command),
        throwsA(isA<ValidationException>()),
      );
    });

    test('non manual mode throws NotManualBasePriceModeException', () async {
      final validator = SetManualBasePriceCommandValidator();
      final command = SetManualBasePriceCommand(
        tenantId: 'tenant-1',
        productId: 'prod-1',
        basePrice: 10000.0,
        mode: 'costing',
      );

      expect(
        () => validator.validate(command),
        throwsA(isA<NotManualBasePriceModeException>()),
      );
    });

    test('scn_e06_u01_fr02_02 missing base unit blocks manual base price', () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = SetManualBasePriceCommandHandler(
        commandGateway: gateway,
        readinessReadPort: _FakeProductReadinessReadPort(hasBaseUnit: false),
        unitGateway: _RecordingCatalogUnitGateway(),
      );

      await expectLater(
        handler.handle(
          SetManualBasePriceCommand(
            tenantId: 'tenant-1',
            productId: 'prod-1',
            basePrice: 10000.0,
          ),
        ),
        throwsA(isA<MissingBaseUnitException>()),
      );
      expect(gateway.lastPriceProfile, isNull);
    });

    test('scn_e06_u01_fr04_01 readiness clears missing_price after set', () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = SetManualBasePriceCommandHandler(
        commandGateway: gateway,
        readinessReadPort: _FakeProductReadinessReadPort(
          hasBaseUnit: true,
          hasBasePrice: true,
          hasStock: true,
        ),
        unitGateway: _RecordingCatalogUnitGateway(),
      );

      final result = await handler.handle(
        SetManualBasePriceCommand(
          tenantId: 'tenant-1',
          productId: 'prod-1',
          basePrice: 80000.0,
        ),
      );

      expect(
        result.readinessSummary.blockers.map((b) => b.code),
        isNot(contains(ReadinessBlockerCode.missingPrice)),
      );
    });
  });

  group('SetInitialPriceBandCommandHandler & Validator', () {
    test('valid price band sets band on gateway', () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = SetInitialPriceBandCommandHandler(
        commandGateway: gateway,
        readinessReadPort: _FakeProductReadinessReadPort(hasBaseUnit: true),
      );
      final validator = SetInitialPriceBandCommandValidator();

      final command = SetInitialPriceBandCommand(
        tenantId: 'tenant-1',
        productId: 'prod-1',
        listPrice: 100000.0,
        floorPrice: 80000.0,
      );

      await validator.validate(command);
      await handler.handle(command);

      expect(gateway.lastProductId, 'prod-1');
      expect(gateway.lastPriceBand!.listPrice!.amount, 100000.0);
      expect(gateway.lastPriceBand!.floorPrice!.amount, 80000.0);
    });

    test('omitted product unit id leaves null for RPC base-unit resolution', () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = SetInitialPriceBandCommandHandler(
        commandGateway: gateway,
        readinessReadPort: _FakeProductReadinessReadPort(hasBaseUnit: true),
      );

      await handler.handle(
        SetInitialPriceBandCommand(
          tenantId: 'tenant-1',
          productId: 'prod-1',
          listPrice: 100000.0,
          floorPrice: 80000.0,
        ),
      );

      expect(gateway.lastPriceBand!.productUnitId, isNull);
    });

    test('floor price greater than list price throws exception', () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = SetInitialPriceBandCommandHandler(
        commandGateway: gateway,
        readinessReadPort: _FakeProductReadinessReadPort(hasBaseUnit: true),
      );
      final validator = SetInitialPriceBandCommandValidator();

      final command = SetInitialPriceBandCommand(
        tenantId: 'tenant-1',
        productId: 'prod-1',
        listPrice: 50000.0,
        floorPrice: 80000.0,
      );

      expect(
        () => validator.validate(command),
        throwsA(isA<FloorPriceGreaterThanListPriceException>()),
      );
      expect(
        () => handler.handle(command),
        throwsA(isA<FloorPriceGreaterThanListPriceException>()),
      );
    });

    test('useStoreRule true without base price throws MissingBasePriceException', () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = SetInitialPriceBandCommandHandler(
        commandGateway: gateway,
        readinessReadPort: _FakeProductReadinessReadPort(hasBaseUnit: true),
      );

      final command = SetInitialPriceBandCommand(
        tenantId: 'tenant-1',
        productId: 'prod-1',
        useStoreRule: true,
      );

      expect(
        () => handler.handle(command),
        throwsA(isA<MissingBasePriceException>()),
      );
    });

    test('scn_e04_u01_fr02_03 missing base unit blocks price band', () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = SetInitialPriceBandCommandHandler(
        commandGateway: gateway,
        readinessReadPort: _FakeProductReadinessReadPort(hasBaseUnit: false),
      );

      await expectLater(
        handler.handle(
          SetInitialPriceBandCommand(
            tenantId: 'tenant-1',
            productId: 'prod-1',
            listPrice: 100000.0,
            floorPrice: 80000.0,
          ),
        ),
        throwsA(isA<MissingBaseUnitException>()),
      );
      expect(gateway.lastPriceBand, isNull);
    });
  });
}
