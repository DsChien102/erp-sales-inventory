import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'support/fake_write_ports.dart';

class _RecordingProductCommandGateway implements IProductCommandGateway {
  DeactivateProductCommand? lastDeactivateCommand;
  ReactivateProductCommand? lastReactivateCommand;

  @override
  Future<String> create({
    required Product product,
    required String idempotencyKey,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> setInitialPriceBand({
    required String productId,
    required String tenantId,
    required ProductUnitPriceBand priceBand,
  }) async {}

  @override
  Future<void> setBasicStockQuantityBase({
    required String productId,
    required String tenantId,
    required ProductStockProfile profile,
  }) async {}

  @override
  Future<void> setManualBasePrice({
    required String productId,
    required String tenantId,
    required ProductBasePriceProfile profile,
    String currency = 'VND',
  }) async {}

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

  @override
  Future<ChangeProductBusinessStatusResult> deactivateProduct(
    DeactivateProductCommand command,
  ) async {
    lastDeactivateCommand = command;
    return ChangeProductBusinessStatusResult(
      productId: command.productId,
      previousStatus: ProductBusinessStatus.active,
      currentStatus: ProductBusinessStatus.inactive,
      readinessSummary: const ReadinessSummaryDto(
        status: ReadinessStatus.incomplete,
        blockers: [
          ReadinessBlockerDto(
            code: ReadinessBlockerCode.missingPriceBand,
            message: 'Thiếu khung giá bán',
            group: 'priceBand',
          ),
        ],
      ),
      version: 2,
      reason: command.reason,
      historyEntry: ProductChangeHistoryEntryDto(
        id: 'history-1',
        occurredAt: DateTime.utc(2026, 7, 7, 9),
        actorDisplayName: command.actorId,
        changeType: ProductChangeHistoryAction.statusChanged,
        summary: 'Ngừng kinh doanh sản phẩm',
        valueBefore: ProductBusinessStatus.active.name,
        valueAfter: ProductBusinessStatus.inactive.name,
      ),
    );
  }

  @override
  Future<ChangeProductBusinessStatusResult> reactivateProduct(
    ReactivateProductCommand command,
  ) async {
    lastReactivateCommand = command;
    return ChangeProductBusinessStatusResult(
      productId: command.productId,
      previousStatus: ProductBusinessStatus.inactive,
      currentStatus: ProductBusinessStatus.active,
      readinessSummary: const ReadinessSummaryDto(
        status: ReadinessStatus.readyToSell,
        blockers: [],
      ),
      version: 3,
      reason: command.reason,
      historyEntry: ProductChangeHistoryEntryDto(
        id: 'history-2',
        occurredAt: DateTime.utc(2026, 7, 7, 10),
        actorDisplayName: command.actorId,
        changeType: ProductChangeHistoryAction.statusChanged,
        summary: 'Kinh doanh lại sản phẩm',
        valueBefore: ProductBusinessStatus.inactive.name,
        valueAfter: ProductBusinessStatus.active.name,
      ),
    );
  }

  @override
  Future<ChangeProductSoftDeleteResult> deleteProduct(
    DeleteProductCommand command,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ChangeProductSoftDeleteResult> restoreProduct(
    RestoreProductCommand command,
  ) async {
    throw UnimplementedError();
  }
}

void main() {
  group('Product business status handlers', () {
    test('scn_e07_u02_fr01_01 deactivate delegates and returns status result', () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = DeactivateProductCommandHandler(
        commandGateway: gateway,
        productWritePort: FakeProductWritePort.active(productId: 'product-4'),
      );

      final result = await handler.handle(
        DeactivateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productId: 'product-4',
          reason: 'Ngừng kinh doanh theo mùa',
          expectedVersion: 1,
          confirmAcknowledgeWarnings: true,
        ),
      );

      expect(gateway.lastDeactivateCommand?.productId, 'product-4');
      expect(gateway.lastDeactivateCommand?.expectedVersion, 1);
      expect(gateway.lastDeactivateCommand?.confirmAcknowledgeWarnings, isTrue);
      expect(result.currentStatus, ProductBusinessStatus.inactive);
      expect(result.version, 2);
      expect(result.historyEntry?.valueBefore, ProductBusinessStatus.active.name);
      expect(result.historyEntry?.valueAfter, ProductBusinessStatus.inactive.name);
    });

    test('scn_e07_u02_fr02_01 reactivate delegates and returns readiness', () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = ReactivateProductCommandHandler(
        commandGateway: gateway,
        productWritePort: FakeProductWritePort.inactive(productId: 'product-5'),
      );

      final result = await handler.handle(
        ReactivateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productId: 'product-5',
          reason: 'Kinh doanh lại',
          expectedVersion: 2,
        ),
      );

      expect(gateway.lastReactivateCommand?.productId, 'product-5');
      expect(gateway.lastReactivateCommand?.expectedVersion, 2);
      expect(result.currentStatus, ProductBusinessStatus.active);
      expect(result.readinessSummary.status, ReadinessStatus.readyToSell);
      expect(result.version, 3);
    });
  });

  group('Product business status validators', () {
    test('deactivate validator rejects blank identifiers', () async {
      final validator = DeactivateProductCommandValidator();

      await expectLater(
        validator.validate(
          DeactivateProductCommand(
            tenantId: ' ',
            actorId: 'user-1',
            productId: 'product-1',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        validator.validate(
          DeactivateProductCommand(
            tenantId: 'tenant-1',
            actorId: ' ',
            productId: 'product-1',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        validator.validate(
          DeactivateProductCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: ' ',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('reactivate validator rejects blank identifiers', () async {
      final validator = ReactivateProductCommandValidator();

      await expectLater(
        validator.validate(
          ReactivateProductCommand(
            tenantId: ' ',
            actorId: 'user-1',
            productId: 'product-1',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        validator.validate(
          ReactivateProductCommand(
            tenantId: 'tenant-1',
            actorId: ' ',
            productId: 'product-1',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        validator.validate(
          ReactivateProductCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: ' ',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
