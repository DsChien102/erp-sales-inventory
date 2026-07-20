import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

final class _RecordingGateway implements IGuidedProductCommandGateway {
  CreateGuidedProductCommand? received;

  @override
  Future<CreateGuidedProductResult> createGuidedProduct(
    CreateGuidedProductCommand command,
  ) async {
    received = command;
    return const CreateGuidedProductResult(
      productId: 'product-1',
      readinessSummary: ReadinessSummaryDto(
        status: ReadinessStatus.incomplete,
      ),
    );
  }
}

void main() {
  group('CreateGuidedProductCommandValidator', () {
    final validator = CreateGuidedProductCommandValidator();

    test('rejects negative basic stock quantity base', () async {
      await expectLater(
        validator.validate(
          CreateGuidedProductCommand(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            productName: 'Thuoc A',
            baseUnit: const NewTenantUnit('hop'),
            basicStockQuantityBase: -1,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('requires a base unit when stock is provided', () async {
      await expectLater(
        validator.validate(
          CreateGuidedProductCommand(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            productName: 'Thuoc A',
            basicStockQuantityBase: 0,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts optional non-negative integer stock', () async {
      await validator.validate(
        CreateGuidedProductCommand(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          productName: 'Thuoc A',
          baseUnit: const NewTenantUnit('hop'),
          basicStockQuantityBase: 12,
        ),
      );
    });

    test('accepts a customConfig price band with persisted ratios', () async {
      await validator.validate(
        CreateGuidedProductCommand(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          productName: 'Thuốc A',
          baseUnit: const NewTenantUnit('lọ'),
          basePrice: 50000,
          listBeforeVat: 75000,
          floorBeforeVat: 70000,
          priceBandSourceType: PriceBandSourceType.customConfig,
          listMarkupRatio: 0.5,
          floorMarkupRatio: 0.4,
        ),
      );
    });

    test('accepts customConfig ratios without a base price', () async {
      await validator.validate(
        CreateGuidedProductCommand(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          productName: 'Thuốc A',
          baseUnit: const NewTenantUnit('lọ'),
          priceBandSourceType: PriceBandSourceType.customConfig,
          listMarkupRatio: 0.5,
          floorMarkupRatio: 0.4,
        ),
      );
    });

    test('accepts default store rule without unit or base price', () async {
      await validator.validate(
        CreateGuidedProductCommand(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          productName: 'Thuốc A',
          useStorePriceRule: true,
          priceBandSourceType: PriceBandSourceType.ruleBased,
        ),
      );
    });

    test('still requires a base unit for custom or manual pricing', () async {
      await expectLater(
        validator.validate(
          CreateGuidedProductCommand(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            productName: 'Thuốc custom',
            basePrice: 50000,
            priceBandSourceType: PriceBandSourceType.customConfig,
            listMarkupRatio: 0.3,
            floorMarkupRatio: 0.1,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        validator.validate(
          CreateGuidedProductCommand(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            productName: 'Thuốc manual',
            priceBandSourceType: PriceBandSourceType.manual,
            listBeforeVat: 70000,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  test('handler delegates the whole command to one gateway call', () async {
    final gateway = _RecordingGateway();
    final handler = CreateGuidedProductCommandHandler(gateway: gateway);
    final command = CreateGuidedProductCommand(
      id: 'idempotency-1',
      tenantId: 'tenant-1',
      actorId: 'actor-1',
      productName: 'Thuoc A',
      baseUnit: const NewTenantUnit('hop'),
      basicStockQuantityBase: 12,
      basePrice: 10000,
      listBeforeVat: 13000,
      floorBeforeVat: 11000,
    );

    final result = await handler.handle(command);

    expect(result.productId, 'product-1');
    expect(gateway.received, same(command));
  });
}
