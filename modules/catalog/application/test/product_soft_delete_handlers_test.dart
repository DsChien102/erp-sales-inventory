import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

class _RecordingProductDeletionGateway implements IProductDeletionGateway {
  CheckProductDeletionEligibilityQuery? lastQuery;

  @override
  Future<ProductDeletionEligibilityDto> checkDeletionEligibility(
    CheckProductDeletionEligibilityQuery query,
  ) async {
    lastQuery = query;
    if (query.productId == 'product-4') {
      return const ProductDeletionEligibilityDto(
        productId: 'product-4',
        canDelete: false,
        issues: [
          ProductDeletionIssueDto(
            code: ProductDeletionIssueCode.openTransaction,
            message: 'Sản phẩm đang được dùng trong giao dịch mở.',
            severity: ProductDeletionIssueSeverity.blocker,
          ),
        ],
      );
    }
    return ProductDeletionEligibilityDto(
      productId: query.productId,
      canDelete: true,
    );
  }
}

class _RecordingProductCommandGateway implements IProductCommandGateway {
  DeleteProductCommand? lastDeleteCommand;
  RestoreProductCommand? lastRestoreCommand;

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
  Future<void> setInitialStock({
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
    throw UnimplementedError();
  }

  @override
  Future<ChangeProductBusinessStatusResult> reactivateProduct(
    ReactivateProductCommand command,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ChangeProductSoftDeleteResult> deleteProduct(
    DeleteProductCommand command,
  ) async {
    lastDeleteCommand = command;
    return ChangeProductSoftDeleteResult(
      productId: command.productId,
      isSoftDeleted: true,
      businessStatus: ProductStatus.active,
      readinessSummary: const ReadinessSummaryDto(
        status: ReadinessStatus.readyToSell,
        blockers: [],
      ),
      version: 2,
      reason: command.reason,
      historyEntry: ProductChangeHistoryEntryDto(
        id: 'history-delete-1',
        occurredAt: DateTime.utc(2026, 7, 7, 11),
        actorDisplayName: command.actorId,
        changeType: 'product_soft_deleted',
        summary: 'Xóa mềm sản phẩm',
        valueBefore: 'false',
        valueAfter: 'true',
      ),
    );
  }

  @override
  Future<ChangeProductSoftDeleteResult> restoreProduct(
    RestoreProductCommand command,
  ) async {
    lastRestoreCommand = command;
    return ChangeProductSoftDeleteResult(
      productId: command.productId,
      isSoftDeleted: false,
      businessStatus: ProductStatus.inactive,
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
      version: 3,
      reason: command.reason,
      historyEntry: ProductChangeHistoryEntryDto(
        id: 'history-restore-1',
        occurredAt: DateTime.utc(2026, 7, 7, 12),
        actorDisplayName: command.actorId,
        changeType: 'product_restored',
        summary: 'Khôi phục sản phẩm',
        valueBefore: 'true',
        valueAfter: 'false',
      ),
    );
  }
}

void main() {
  group('Product soft delete handlers', () {
    test('scn_e07_u03_fr01_01 eligibility allows product without dependencies', () async {
      final gateway = _RecordingProductDeletionGateway();
      final handler = CheckProductDeletionEligibilityQueryHandler(
        deletionGateway: gateway,
      );

      final result = await handler.handle(
        CheckProductDeletionEligibilityQuery(
          tenantId: 'tenant-1',
          productId: 'product-6',
        ),
      );

      expect(gateway.lastQuery?.productId, 'product-6');
      expect(result.canDelete, isTrue);
      expect(result.issues, isEmpty);
    });

    test('scn_e07_u03_fr01_02 eligibility returns open transaction blocker', () async {
      final gateway = _RecordingProductDeletionGateway();
      final handler = CheckProductDeletionEligibilityQueryHandler(
        deletionGateway: gateway,
      );

      final result = await handler.handle(
        CheckProductDeletionEligibilityQuery(
          tenantId: 'tenant-1',
          productId: 'product-4',
        ),
      );

      expect(result.canDelete, isFalse);
      expect(result.blockers.single.code, ProductDeletionIssueCode.openTransaction);
    });

    test('scn_e07_u03_fr02_01 delete delegates and returns soft delete result', () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = DeleteProductCommandHandler(
        commandGateway: gateway,
      );

      final result = await handler.handle(
        DeleteProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productId: 'product-6',
          reason: 'Dọn danh mục',
          expectedVersion: 1,
          confirmAcknowledgeWarnings: true,
        ),
      );

      expect(gateway.lastDeleteCommand?.productId, 'product-6');
      expect(gateway.lastDeleteCommand?.expectedVersion, 1);
      expect(gateway.lastDeleteCommand?.confirmAcknowledgeWarnings, isTrue);
      expect(result.isSoftDeleted, isTrue);
      expect(result.version, 2);
      expect(result.historyEntry?.valueBefore, 'false');
      expect(result.historyEntry?.valueAfter, 'true');
    });

    test('scn_e07_u03_fr03_01 restore delegates and returns inactive readiness', () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = RestoreProductCommandHandler(
        commandGateway: gateway,
      );

      final result = await handler.handle(
        RestoreProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productId: 'product-7',
          reason: 'Khôi phục nhầm xóa',
          expectedVersion: 2,
        ),
      );

      expect(gateway.lastRestoreCommand?.productId, 'product-7');
      expect(gateway.lastRestoreCommand?.expectedVersion, 2);
      expect(result.isSoftDeleted, isFalse);
      expect(result.businessStatus, ProductStatus.inactive);
      expect(result.readinessSummary.status, ReadinessStatus.incomplete);
      expect(
        result.readinessSummary.blockers.single.code,
        ReadinessBlockerCode.missingPriceBand,
      );
    });
  });

  group('Product soft delete validators', () {
    test('eligibility validator rejects blank identifiers', () async {
      final validator = CheckProductDeletionEligibilityQueryValidator();

      await expectLater(
        validator.validate(
          CheckProductDeletionEligibilityQuery(
            tenantId: ' ',
            productId: 'product-1',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        validator.validate(
          CheckProductDeletionEligibilityQuery(
            tenantId: 'tenant-1',
            productId: ' ',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('delete validator rejects blank identifiers', () async {
      final validator = DeleteProductCommandValidator();

      await expectLater(
        validator.validate(
          DeleteProductCommand(
            tenantId: ' ',
            actorId: 'user-1',
            productId: 'product-1',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        validator.validate(
          DeleteProductCommand(
            tenantId: 'tenant-1',
            actorId: ' ',
            productId: 'product-1',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        validator.validate(
          DeleteProductCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: ' ',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('restore validator rejects blank identifiers', () async {
      final validator = RestoreProductCommandValidator();

      await expectLater(
        validator.validate(
          RestoreProductCommand(
            tenantId: ' ',
            actorId: 'user-1',
            productId: 'product-1',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        validator.validate(
          RestoreProductCommand(
            tenantId: 'tenant-1',
            actorId: ' ',
            productId: 'product-1',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        validator.validate(
          RestoreProductCommand(
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
