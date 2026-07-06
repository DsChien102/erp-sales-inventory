import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';

class _RecordingProductCommandGateway implements IProductCommandGateway {
  Product? lastProduct;
  String? lastIdempotencyKey;
  Exception? throwOnCreate;

  @override
  Future<String> create({
    required Product product,
    required String idempotencyKey,
  }) async {
    if (throwOnCreate != null) {
      throw throwOnCreate!;
    }
    lastProduct = product;
    lastIdempotencyKey = idempotencyKey;
    return 'product-registered-id';
  }

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
  }) async {}

  @override
  Future<void> setInitialPriceBand({
    required String productId,
    required String tenantId,
    required ProductUnitPriceBand priceBand,
  }) async {}
}

void main() {
  group('CreateProductCommandHandler', () {
    test('scn_e02_u01_fr01_01 creates product with images and primary default',
        () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = CreateProductCommandHandler(commandGateway: gateway);

      final result = await handler.handle(
        CreateProductCommand(
          id: 'idem-1',
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productName: 'Amoxicillin 100ml',
          images: const [
            ProductImageInput(storageKey: 'img-1', sortOrder: 0),
            ProductImageInput(storageKey: 'img-2', sortOrder: 1),
          ],
        ),
      );

      expect(result.productId, 'product-registered-id');
      expect(gateway.lastIdempotencyKey, 'idem-1');
      expect(gateway.lastProduct, isNotNull);
      expect(gateway.lastProduct!.name.value, 'Amoxicillin 100ml');
      expect(gateway.lastProduct!.images, hasLength(2));
      expect(gateway.lastProduct!.images.first.isPrimary, isTrue);
      expect(
        result.readinessSummary.blockers.map((b) => b.code),
        isNot(contains(ReadinessBlockerCode.missingImage)),
      );
    });

    test('scn_e02_u01_fr02_01 propagates DuplicateSkuException from gateway',
        () async {
      final gateway = _RecordingProductCommandGateway()
        ..throwOnCreate = DuplicateSkuException(
          sku: 'SKU-001',
          existingProductId: 'product-existing-1',
          existingProductName: 'Existing Product',
        );
      final handler = CreateProductCommandHandler(commandGateway: gateway);

      await expectLater(
        handler.handle(
          CreateProductCommand(
            tenantId: 'tenant-1',
            actorId: 'user-1',
            productName: 'Thuốc A',
            sku: 'SKU-001',
          ),
        ),
        throwsA(
          isA<DuplicateSkuException>().having((e) => e.sku, 'sku', 'SKU-001'),
        ),
      );
    });

    test('scn_e02_u01_fr03_01 readiness reflects base unit presence', () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = CreateProductCommandHandler(commandGateway: gateway);

      final withUnit = await handler.handle(
        CreateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productName: 'Thuốc A',
          baseUnitName: 'Lọ',
        ),
      );
      expect(
        withUnit.readinessSummary.blockers.map((b) => b.code),
        isNot(contains(ReadinessBlockerCode.missingBaseUnit)),
      );
      expect(gateway.lastProduct!.baseUnit?.name, 'Lọ');

      final withoutUnit = await handler.handle(
        CreateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productName: 'Thuốc B',
        ),
      );
      expect(
        withoutUnit.readinessSummary.blockers.map((b) => b.code),
        contains(ReadinessBlockerCode.missingBaseUnit),
      );
    });

    test('scn_e02_u01_fr04_01 seeds active status and missing_price readiness',
        () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = CreateProductCommandHandler(commandGateway: gateway);

      final result = await handler.handle(
        CreateProductCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          productName: 'Thuốc C',
          baseUnitName: 'Hộp',
        ),
      );

      expect(gateway.lastProduct!.status, ProductStatus.active);
      expect(result.readinessSummary.status, ReadinessStatus.incomplete);
      expect(
        result.readinessSummary.blockers.map((b) => b.code),
        contains(ReadinessBlockerCode.missingPrice),
      );
    });
  });
}
