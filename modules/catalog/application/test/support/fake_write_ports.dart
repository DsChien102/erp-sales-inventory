import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Minimal write-port fake for handler unit tests.
final class FakeProductWritePort implements IProductWritePort {
  FakeProductWritePort({Product? product}) : _product = product;

  Product? _product;

  factory FakeProductWritePort.active({
    String productId = 'product-1',
    String tenantId = 'tenant-1',
    String name = 'Thuoc A',
  }) {
    final id = ProductId(productId);
    final now = DateTime.utc(2026, 1, 1);
    return FakeProductWritePort(
      product: Product.reconstitute(
        id: id,
        tenantId: TenantId(tenantId),
        referenceId: ProductReferenceId(
          'PREF$productId'.replaceAll('-', '').padRight(8, '0').substring(0, 8),
        ),
        name: ProductName(name),

        status: ProductBusinessStatus.active,
        readiness: ProductReadiness.seedFromCreate(
          productId: productId,
          productName: name,
          hasBaseUnit: true,
          hasImages: false,
        ),
        images: const [],
        createdBy: 'system',
        createdAt: now,
        updatedBy: 'system',
        updatedAt: now,
        version: 1,
      ),
    );
  }

  factory FakeProductWritePort.inactive({
    String productId = 'product-5',
    String tenantId = 'tenant-1',
  }) {
    final fake = FakeProductWritePort.active(
      productId: productId,
      tenantId: tenantId,
    );
    fake._product = fake._product!.deactivate(actorId: 'system');
    return fake;
  }

  factory FakeProductWritePort.softDeleted({
    String productId = 'product-1',
    String tenantId = 'tenant-1',
  }) {
    final fake = FakeProductWritePort.active(
      productId: productId,
      tenantId: tenantId,
    );
    fake._product = fake._product!.softDelete(actorId: 'system');
    return fake;
  }

  @override
  Future<Product?> load({
    required String tenantId,
    required String productId,
  }) async {
    return _product;
  }
}

/// Minimal catalog read gateway for stock adjust / apply-rule tests.
final class FakeCatalogReadGateway implements ICatalogReadGateway {
  FakeCatalogReadGateway({
    this.stockQuantity = 150,
    this.basePriceAmount = 25000,
  });

  final int? stockQuantity;
  final double? basePriceAmount;

  @override
  Future<ProductControlCenterReadModel?> loadControlCenter({
    required String tenantId,
    required String productId,
  }) async {
    return ProductControlCenterReadModel(
      productId: productId,
      name: 'Thuoc A',
      businessStatus: ProductBusinessStatus.active,
      facts: ProductReadinessFacts(
        productId: productId,
        productName: 'Thuoc A',
        hasBaseUnit: true,
        hasImages: true,
        hasStock: true,
        hasBasePrice: basePriceAmount != null,
        hasPriceBand: true,
        hasRequiredCustomFields: true,
      ),
      stockQuantity: stockQuantity,
      basePriceAmount: basePriceAmount,
    );
  }

  @override
  Future<ProductSearchResultDto> search({
    required String tenantId,
    required ProductSearchCriteria criteria,
    required int limit,
    required int offset,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ProductListItemDto?> findByBarcode({
    required String tenantId,
    required String barcode,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<CustomFieldFilterOptionDto>> listCustomFieldFilterOptions({
    required String tenantId,
    required int maxOptionsPerField,
  }) {
    throw UnimplementedError();
  }
}
