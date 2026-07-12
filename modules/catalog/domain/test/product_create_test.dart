import 'package:test/test.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('Product.create', () {
    test('creates active product with readiness and domain event', () {
      final product = Product.create(
        id: const ProductId('product-1'),
        tenantId: const TenantId('tenant-1'),
        referenceId: ProductReferenceId('SP-0001'),
        name: ProductName('Amoxicillin 100ml'),
        actorId: 'user-1',
        baseUnit: ProductBaseUnit('Lọ'),
      );

      expect(product.status, ProductBusinessStatus.active);
      expect(product.name.value, 'Amoxicillin 100ml');
      expect(product.baseUnit?.name, 'Lọ');
      expect(product.readiness.status, ReadinessStatus.incomplete);
      expect(
        product.readiness.blockers.map((b) => b.code),
        containsAll([
          ReadinessBlockerCode.missingPrice,
          ReadinessBlockerCode.missingImage,
          ReadinessBlockerCode.missingStock,
          ReadinessBlockerCode.missingPriceBand,
        ]),
      );
      expect(
        product.readiness.blockers.map((b) => b.code),
        isNot(contains(ReadinessBlockerCode.missingBaseUnit)),
      );
      expect(product.domainEvents, hasLength(1));
      expect(product.domainEvents!.first, isA<ProductCreated>());
    });

    test('defaults first image as primary when none selected', () {
      final product = Product.create(
        id: const ProductId('product-2'),
        tenantId: const TenantId('tenant-1'),
        referenceId: ProductReferenceId('SP-0001'),
        name: ProductName('Thuốc A'),
        actorId: 'user-1',
        images: const [
          ProductImage(storageKey: 'img-1', isPrimary: false, sortOrder: 0),
          ProductImage(storageKey: 'img-2', isPrimary: false, sortOrder: 1),
        ],
      );

      expect(product.images.first.isPrimary, isTrue);
      expect(product.images[1].isPrimary, isFalse);
      expect(
        product.readiness.blockers.map((b) => b.code),
        isNot(contains(ReadinessBlockerCode.missingImage)),
      );
    });

    test('records missing_base_unit when base unit omitted', () {
      final product = Product.create(
        id: const ProductId('product-3'),
        tenantId: const TenantId('tenant-1'),
        referenceId: ProductReferenceId('SP-0001'),
        name: ProductName('Thuốc B'),
        actorId: 'user-1',
      );

      expect(
        product.readiness.blockers.map((b) => b.code),
        contains(ReadinessBlockerCode.missingBaseUnit),
      );
    });

    test('throws when product name is empty', () {
      expect(
        () => ProductName('   '),
        throwsA(isA<DomainException>()),
      );
    });

    test('throws when more than one primary image', () {
      expect(
        () => Product.create(
          id: const ProductId('product-4'),
          tenantId: const TenantId('tenant-1'),
          referenceId: ProductReferenceId('SP-0004'),
          name: ProductName('Thuốc C'),
          actorId: 'user-1',
          images: const [
            ProductImage(storageKey: 'img-1', isPrimary: true, sortOrder: 0),
            ProductImage(storageKey: 'img-2', isPrimary: true, sortOrder: 1),
          ],
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });
}
