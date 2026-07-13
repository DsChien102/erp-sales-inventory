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
