import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

final class _RecordingCatalogUnitGateway implements ICatalogUnitGateway {
  _RecordingCatalogUnitGateway({
    this.result,
    this.duplicate = false,
    this.units = const [],
    this.throwOnSet,
  });

  SetProductBaseUnitResult? result;
  bool duplicate;
  List<TenantMeasurementUnitDto> units;
  Object? throwOnSet;

  SetProductBaseUnitCommand? lastSetCommand;
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
}

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
}
