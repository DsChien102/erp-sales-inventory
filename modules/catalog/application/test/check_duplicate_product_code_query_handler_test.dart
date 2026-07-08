import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

class _FakeProductDuplicateChecker implements IProductDuplicateChecker {
  @override
  Future<List<ProductDuplicateMatch>> findMatches({
    required TenantId tenantId,
    Sku? sku,
    Barcode? barcode,
    ProductId? excludeProductId,
  }) async {
    if (sku != null) {
      return [
        ProductDuplicateMatch(
          field: ProductDuplicateField.sku,
          productId: const ProductId('product-existing-1'),
          productName: 'Existing Product',
          matchedValue: sku.value,
        ),
      ];
    }
    if (barcode != null) {
      return [
        ProductDuplicateMatch(
          field: ProductDuplicateField.barcode,
          productId: const ProductId('product-existing-1'),
          productName: 'Existing Product',
          matchedValue: barcode.value,
        ),
      ];
    }
    return const [];
  }
}

void main() {
  group('CheckDuplicateProductCodeQueryHandler', () {
    test('scn_e02_u01_fr02_01 maps duplicate matches to DTOs', () async {
      final handler = CheckDuplicateProductCodeQueryHandler(
        duplicateChecker: _FakeProductDuplicateChecker(),
      );

      final matches = await handler.handle(
        CheckDuplicateProductCodeQuery(
          tenantId: 'tenant-1',
          sku: 'SKU-001',
        ),
      );

      expect(matches, hasLength(1));
      expect(matches.single.field, ProductDuplicateField.sku);
      expect(matches.single.productId, 'product-existing-1');
      expect(matches.single.productName, 'Existing Product');
      expect(matches.single.matchedValue, 'SKU-001');
    });
  });
}
