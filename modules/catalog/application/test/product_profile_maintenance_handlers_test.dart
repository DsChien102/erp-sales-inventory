import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

class _RecordingProductCommandGateway implements IProductCommandGateway {
  UpdateProductProfileCommand? lastProfileCommand;
  UpdateProductImagesCommand? lastImagesCommand;

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
    lastProfileCommand = command;
    return UpdateProductProfileResult(
      productId: command.productId,
      profile: ProductProfileSummaryDto(
        productId: command.productId,
        name: command.productName.trim(),
        tradeName: 'Amo 500',
        sku: 'SKU-NEW',
        barcode: '8930000000099',
        businessStatus: ProductStatus.active,
      ),
      readinessSummary: const ReadinessSummaryDto(
        status: ReadinessStatus.readyToSell,
        blockers: [],
      ),
      version: 2,
    );
  }

  @override
  Future<UpdateProductImagesResult> updateProductImages(
    UpdateProductImagesCommand command,
  ) async {
    lastImagesCommand = command;
    return UpdateProductImagesResult(
      productId: command.productId,
      images: const [
        ProductImageDto(
          imageId: 'image-1',
          storageKey: 'tenant-1/products/product-1/image-1.webp',
          url: 'https://cdn.fake/image-1.webp',
          isPrimary: true,
        ),
      ],
      primaryImageUrl: 'https://cdn.fake/image-1.webp',
      readinessSummary: const ReadinessSummaryDto(
        status: ReadinessStatus.readyToSell,
        blockers: [],
      ),
      version: 2,
    );
  }
}

class _RecordingUploadPort implements IProductImageUploadPort {
  RequestProductImageUploadCommand? lastCreateCommand;
  RequestProductMaintenanceImageUploadCommand? lastMaintenanceCommand;

  @override
  Future<ProductImageUploadSlotDto> reserveUploadSlot(
    RequestProductImageUploadCommand command,
  ) async {
    lastCreateCommand = command;
    throw UnimplementedError();
  }

  @override
  Future<ProductImageUploadSlotDto> reserveMaintenanceUploadSlot(
    RequestProductMaintenanceImageUploadCommand command,
  ) async {
    lastMaintenanceCommand = command;
    return ProductImageUploadSlotDto(
      slotId: 'slot-maintenance-1',
      storageKey: '${command.tenantId}/staging/slot-maintenance-1/original.webp',
      signedUploadUrl: 'https://storage.fake/upload',
      expiresAt: DateTime.utc(2026, 7, 6, 12),
    );
  }
}

void main() {
  group('Product profile maintenance handlers', () {
    test('scn_contract_e07_u01_fr01_01 delegates profile update to gateway', () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = UpdateProductProfileCommandHandler(
        commandGateway: gateway,
      );

      final result = await handler.handle(
        UpdateProductProfileCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productId: 'product-1',
          productName: '  Amoxicillin 500mg hộp mới  ',
          sku: 'SKU-NEW',
          expectedVersion: 1,
        ),
      );

      expect(gateway.lastProfileCommand?.productId, 'product-1');
      expect(gateway.lastProfileCommand?.expectedVersion, 1);
      expect(result.profile.name, 'Amoxicillin 500mg hộp mới');
      expect(result.version, 2);
    });

    test('scn_contract_e07_u01_fr02_01 delegates image snapshot to gateway', () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = UpdateProductImagesCommandHandler(
        commandGateway: gateway,
      );

      final result = await handler.handle(
        UpdateProductImagesCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productId: 'product-1',
          images: const [
            ProductImageMutationInput(
              storageKey: 'tenant-1/products/product-1/image-1.webp',
              isPrimary: true,
            ),
          ],
        ),
      );

      expect(gateway.lastImagesCommand?.images, hasLength(1));
      expect(result.images.single.isPrimary, isTrue);
      expect(result.primaryImageUrl, 'https://cdn.fake/image-1.webp');
    });

    test('maintenance upload handler uses maintenance upload port method', () async {
      final port = _RecordingUploadPort();
      final handler = RequestProductMaintenanceImageUploadCommandHandler(
        uploadPort: port,
      );

      final result = await handler.handle(
        RequestProductMaintenanceImageUploadCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productId: 'product-1',
          fileName: 'photo.webp',
          contentType: 'image/webp',
          byteSize: 1024,
        ),
      );

      expect(port.lastMaintenanceCommand?.productId, 'product-1');
      expect(port.lastCreateCommand, isNull);
      expect(result.slotId, 'slot-maintenance-1');
    });
  });

  group('Product profile maintenance validators', () {
    test('profile validator rejects blank product name', () async {
      final validator = UpdateProductProfileCommandValidator();

      await expectLater(
        validator.validate(
          UpdateProductProfileCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: 'product-1',
            productName: '   ',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('image validator rejects multiple primary images', () async {
      final validator = UpdateProductImagesCommandValidator();

      await expectLater(
        validator.validate(
          UpdateProductImagesCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: 'product-1',
            images: const [
              ProductImageMutationInput(storageKey: 'img-1', isPrimary: true),
              ProductImageMutationInput(storageKey: 'img-2', isPrimary: true),
            ],
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('maintenance upload validator rejects unsupported content type', () async {
      final validator = RequestProductMaintenanceImageUploadCommandValidator();

      await expectLater(
        validator.validate(
          RequestProductMaintenanceImageUploadCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productId: 'product-1',
            fileName: 'photo.gif',
            contentType: 'image/gif',
            byteSize: 1024,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
