import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class _RecordingCatalogUnitGateway implements ICatalogUnitGateway {
  _RecordingCatalogUnitGateway({
    this.result,
    this.duplicate = false,
    this.units = const [],
    this.productUnitsResult,
    this.mutationResult,
    this.throwOnSet,
  });

  SetProductBaseUnitResult? result;
  bool duplicate;
  List<TenantMeasurementUnitDto> units;
  ProductUnitsDto? productUnitsResult;
  ProductUnitMutationResult? mutationResult;
  Object? throwOnSet;

  SetProductBaseUnitCommand? lastSetCommand;
  ListProductUnitsQuery? lastListProductUnitsQuery;
  AddProductConversionUnitCommand? lastAddConversionUnitCommand;
  DeactivateProductConversionUnitCommand? lastDeactivateConversionUnitCommand;
  ReactivateProductConversionUnitCommand? lastReactivateConversionUnitCommand;
  String? lastTenantId;
  String? lastKeyword;
  int? lastLimit;
  String? lastDuplicateName;

  @override
  Future<List<TenantMeasurementUnitDto>> listTenantUnits({
    required String tenantId,
    String? keyword,
    required int limit,
  }) async {
    lastTenantId = tenantId;
    lastKeyword = keyword;
    lastLimit = limit;
    return units;
  }

  @override
  Future<bool> isDuplicateUnitName({
    required String tenantId,
    required String name,
  }) async {
    lastTenantId = tenantId;
    lastDuplicateName = name;
    return duplicate;
  }

  @override
  Future<SetProductBaseUnitResult> setProductBaseUnit({
    required SetProductBaseUnitCommand command,
  }) async {
    lastSetCommand = command;
    final error = throwOnSet;
    if (error != null) {
      throw error;
    }
    return result!;
  }

  @override
  Future<ProductUnitsDto> listProductUnits({
    required ListProductUnitsQuery query,
  }) async {
    lastListProductUnitsQuery = query;
    return productUnitsResult!;
  }

  @override
  Future<ProductUnitMutationResult> addConversionUnit({
    required AddProductConversionUnitCommand command,
  }) async {
    lastAddConversionUnitCommand = command;
    return mutationResult!;
  }

  @override
  Future<ProductUnitMutationResult> deactivateConversionUnit({
    required DeactivateProductConversionUnitCommand command,
  }) async {
    lastDeactivateConversionUnitCommand = command;
    return mutationResult!;
  }

  @override
  Future<ProductUnitMutationResult> reactivateConversionUnit({
    required ReactivateProductConversionUnitCommand command,
  }) async {
    lastReactivateConversionUnitCommand = command;
    return mutationResult!;
  }
}

const _productOneUnits = ProductUnitsDto(
  productId: 'product-1',
  baseUnitName: 'Hộp',
  units: [
    ProductUnitDto(
      id: 'product-1-base',
      name: 'Hộp',
      conversionRateToBase: 1,
      isBaseUnit: true,
      isActive: true,
    ),
    ProductUnitDto(
      id: 'product-1-unit-vi',
      name: 'Vỉ',
      conversionRateToBase: 10,
      isBaseUnit: false,
      isActive: true,
    ),
    ProductUnitDto(
      id: 'product-1-unit-thung',
      name: 'Thùng',
      conversionRateToBase: 100,
      isBaseUnit: false,
      isActive: false,
    ),
  ],
);

const _productSixUnits = ProductUnitsDto(
  productId: 'product-6',
  baseUnitName: '',
  units: [],
);

void main() {
  group('SetProductBaseUnitCommandHandler & Validator', () {
    test('scn_e04_u01_fr01_01 sets existing base unit', () async {
      final gateway = _RecordingCatalogUnitGateway(
        result: SetProductBaseUnitResult(
          productId: 'product-6',
          baseUnitName: 'Lọ',
          readinessSummary: ReadinessSummaryDto.fromDomain(
            ProductReadinessEvaluator.compute(
              const ProductReadinessFacts(
                productId: 'product-6',
                productName: 'Thuốc thiếu đơn vị',
                hasBaseUnit: true,
                hasImages: true,
                hasStock: false,
                hasBasePrice: false,
                hasPriceBand: false,
                hasRequiredCustomFields: true,
              ),
            ),
          ),
        ),
      );
      final handler = SetProductBaseUnitCommandHandler(unitGateway: gateway);
      final validator = SetProductBaseUnitCommandValidator();
      final command = SetProductBaseUnitCommand(
        tenantId: 'tenant-1',
        productId: 'product-6',
        selection: const ExistingTenantUnit('unit-lo'),
      );

      await validator.validate(command);
      final result = await handler.handle(command);

      expect(gateway.lastSetCommand, same(command));
      expect(result.productId, 'product-6');
      expect(result.baseUnitName, 'Lọ');
      expect(
        result.readinessSummary.blockers.map((blocker) => blocker.code),
        isNot(contains(ReadinessBlockerCode.missingBaseUnit)),
      );
    });

    test('scn_e04_u01_fr01_02 creates new base unit', () async {
      final gateway = _RecordingCatalogUnitGateway(
        result: const SetProductBaseUnitResult(
          productId: 'product-6',
          baseUnitName: 'Vỉ',
          readinessSummary: ReadinessSummaryDto(
            status: ReadinessStatus.incomplete,
          ),
        ),
      );
      final handler = SetProductBaseUnitCommandHandler(unitGateway: gateway);

      final result = await handler.handle(
        SetProductBaseUnitCommand(
          tenantId: 'tenant-1',
          productId: 'product-6',
          selection: const NewTenantUnit('Vỉ'),
        ),
      );

      expect(result.baseUnitName, 'Vỉ');
      expect(gateway.lastSetCommand!.selection, isA<NewTenantUnit>());
    });

    test('duplicate new unit bubbles DuplicateMeasurementUnitNameException', () async {
      final gateway = _RecordingCatalogUnitGateway(
        throwOnSet: DuplicateMeasurementUnitNameException(
          name: 'Lọ',
          existingUnitId: 'unit-lo',
        ),
      );
      final handler = SetProductBaseUnitCommandHandler(unitGateway: gateway);

      await expectLater(
        handler.handle(
          SetProductBaseUnitCommand(
            tenantId: 'tenant-1',
            productId: 'product-6',
            selection: const NewTenantUnit('Lọ'),
          ),
        ),
        throwsA(isA<DuplicateMeasurementUnitNameException>()),
      );
    });

    test('inactive existing unit bubbles ValidationException', () async {
      final gateway = _RecordingCatalogUnitGateway(
        throwOnSet: ValidationException('Measurement unit is inactive.'),
      );
      final handler = SetProductBaseUnitCommandHandler(unitGateway: gateway);

      await expectLater(
        handler.handle(
          SetProductBaseUnitCommand(
            tenantId: 'tenant-1',
            productId: 'product-6',
            selection: const ExistingTenantUnit('unit-inactive'),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('product not found bubbles ApplicationException', () async {
      final gateway = _RecordingCatalogUnitGateway(
        throwOnSet: ApplicationException('Product not found'),
      );
      final handler = SetProductBaseUnitCommandHandler(unitGateway: gateway);

      await expectLater(
        handler.handle(
          SetProductBaseUnitCommand(
            tenantId: 'tenant-1',
            productId: 'missing',
            selection: const ExistingTenantUnit('unit-lo'),
          ),
        ),
        throwsA(isA<ApplicationException>()),
      );
    });

    test('validator rejects blank new unit name', () async {
      final validator = SetProductBaseUnitCommandValidator();

      await expectLater(
        validator.validate(
          SetProductBaseUnitCommand(
            tenantId: 'tenant-1',
            productId: 'product-6',
            selection: const NewTenantUnit('  '),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Tenant measurement unit query handlers', () {
    test('lists tenant units through gateway', () async {
      final gateway = _RecordingCatalogUnitGateway(
        units: const [
          TenantMeasurementUnitDto(id: 'unit-lo', name: 'Lọ'),
        ],
      );
      final handler = ListTenantMeasurementUnitsQueryHandler(
        unitGateway: gateway,
      );

      final result = await handler.handle(
        ListTenantMeasurementUnitsQuery(
          tenantId: 'tenant-1',
          keyword: 'l',
          limit: 20,
        ),
      );

      expect(result.single.name, 'Lọ');
      expect(gateway.lastTenantId, 'tenant-1');
      expect(gateway.lastKeyword, 'l');
      expect(gateway.lastLimit, 20);
    });

    test('rejects invalid list limit', () async {
      final validator = ListTenantMeasurementUnitsQueryValidator();

      await expectLater(
        validator.validate(
          ListTenantMeasurementUnitsQuery(
            tenantId: 'tenant-1',
            limit: 101,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('checks duplicate unit name through gateway', () async {
      final gateway = _RecordingCatalogUnitGateway(duplicate: true);
      final handler = CheckDuplicateMeasurementUnitNameQueryHandler(
        unitGateway: gateway,
      );

      final result = await handler.handle(
        CheckDuplicateMeasurementUnitNameQuery(
          tenantId: 'tenant-1',
          name: 'Lọ',
        ),
      );

      expect(result, isTrue);
      expect(gateway.lastTenantId, 'tenant-1');
      expect(gateway.lastDuplicateName, 'Lọ');
    });

    test('rejects blank duplicate-check name', () async {
      final validator = CheckDuplicateMeasurementUnitNameQueryValidator();

      await expectLater(
        validator.validate(
          CheckDuplicateMeasurementUnitNameQuery(
            tenantId: 'tenant-1',
            name: ' ',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Product conversion unit handlers', () {
    test('lists product units through gateway', () async {
      final gateway = _RecordingCatalogUnitGateway(
        productUnitsResult: _productOneUnits,
      );
      final handler = ListProductUnitsQueryHandler(unitGateway: gateway);

      final result = await handler.handle(
        ListProductUnitsQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
          includeInactive: true,
        ),
      );

      expect(result.productId, 'product-1');
      expect(result.units, hasLength(3));
      expect(gateway.lastListProductUnitsQuery?.includeInactive, isTrue);
    });

    test('adds conversion after domain validation', () async {
      const added = ProductUnitDto(
        id: 'product-1-unit-new',
        name: 'Thùng',
        conversionRateToBase: 100,
        isBaseUnit: false,
        isActive: true,
      );
      final command = AddProductConversionUnitCommand(
        tenantId: 'tenant-1',
        productId: 'product-1',
        unitName: 'Thùng',
        conversionRateToBase: 100,
      );
      final gateway = _RecordingCatalogUnitGateway(
        productUnitsResult: _productOneUnits,
        mutationResult: const ProductUnitMutationResult(
          productId: 'product-1',
          unit: added,
        ),
      );
      final handler = AddProductConversionUnitCommandHandler(
        unitGateway: gateway,
      );

      final result = await handler.handle(command);

      expect(result.unit, same(added));
      expect(gateway.lastListProductUnitsQuery?.productId, 'product-1');
      expect(gateway.lastListProductUnitsQuery?.includeInactive, isTrue);
      expect(gateway.lastAddConversionUnitCommand, same(command));
    });

    test('add conversion blocks before gateway mutation when base unit is missing', () async {
      final gateway = _RecordingCatalogUnitGateway(
        productUnitsResult: _productSixUnits,
        mutationResult: const ProductUnitMutationResult(
          productId: 'product-6',
          unit: ProductUnitDto(
            id: 'unused',
            name: 'Hộp',
            conversionRateToBase: 10,
            isBaseUnit: false,
            isActive: true,
          ),
        ),
      );
      final handler = AddProductConversionUnitCommandHandler(
        unitGateway: gateway,
      );

      await expectLater(
        handler.handle(
          AddProductConversionUnitCommand(
            tenantId: 'tenant-1',
            productId: 'product-6',
            unitName: 'Hộp',
            conversionRateToBase: 10,
          ),
        ),
        throwsA(isA<MissingBaseUnitException>()),
      );
      expect(gateway.lastAddConversionUnitCommand, isNull);
    });

    test('deactivates conversion after domain validation', () async {
      final command = DeactivateProductConversionUnitCommand(
        tenantId: 'tenant-1',
        productId: 'product-1',
        productUnitId: 'product-1-unit-vi',
      );
      final gateway = _RecordingCatalogUnitGateway(
        productUnitsResult: _productOneUnits,
        mutationResult: const ProductUnitMutationResult(
          productId: 'product-1',
          unit: ProductUnitDto(
            id: 'product-1-unit-vi',
            name: 'Vỉ',
            conversionRateToBase: 10,
            isBaseUnit: false,
            isActive: false,
          ),
        ),
      );
      final handler = DeactivateProductConversionUnitCommandHandler(
        unitGateway: gateway,
      );

      final result = await handler.handle(command);

      expect(result.unit.isActive, isFalse);
      expect(gateway.lastDeactivateConversionUnitCommand, same(command));
    });

    test('deactivate base unit blocks before gateway mutation', () async {
      final gateway = _RecordingCatalogUnitGateway(
        productUnitsResult: _productOneUnits,
        mutationResult: const ProductUnitMutationResult(
          productId: 'product-1',
          unit: ProductUnitDto(
            id: 'product-1-base',
            name: 'Hộp',
            conversionRateToBase: 1,
            isBaseUnit: true,
            isActive: false,
          ),
        ),
      );
      final handler = DeactivateProductConversionUnitCommandHandler(
        unitGateway: gateway,
      );

      await expectLater(
        handler.handle(
          DeactivateProductConversionUnitCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            productUnitId: 'product-1-base',
          ),
        ),
        throwsA(isA<DomainException>()),
      );
      expect(gateway.lastDeactivateConversionUnitCommand, isNull);
    });

    test('reactivates conversion after domain validation', () async {
      final command = ReactivateProductConversionUnitCommand(
        tenantId: 'tenant-1',
        productId: 'product-1',
        productUnitId: 'product-1-unit-thung',
      );
      final gateway = _RecordingCatalogUnitGateway(
        productUnitsResult: _productOneUnits,
        mutationResult: const ProductUnitMutationResult(
          productId: 'product-1',
          unit: ProductUnitDto(
            id: 'product-1-unit-thung',
            name: 'Thùng',
            conversionRateToBase: 100,
            isBaseUnit: false,
            isActive: true,
          ),
        ),
      );
      final handler = ReactivateProductConversionUnitCommandHandler(
        unitGateway: gateway,
      );

      final result = await handler.handle(command);

      expect(result.unit.isActive, isTrue);
      expect(gateway.lastReactivateConversionUnitCommand, same(command));
    });

    test('validators reject blank ids and invalid rate', () async {
      await expectLater(
        ListProductUnitsQueryValidator().validate(
          ListProductUnitsQuery(tenantId: 'tenant-1', productId: ' '),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        AddProductConversionUnitCommandValidator().validate(
          AddProductConversionUnitCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            unitName: 'Vỉ',
            conversionRateToBase: 0,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        DeactivateProductConversionUnitCommandValidator().validate(
          DeactivateProductConversionUnitCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            productUnitId: ' ',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        ReactivateProductConversionUnitCommandValidator().validate(
          ReactivateProductConversionUnitCommand(
            tenantId: ' ',
            productId: 'product-1',
            productUnitId: 'product-1-unit-vi',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
