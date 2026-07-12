import 'package:test/test.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('Product lifecycle', () {
    Product createProduct() => Product.create(
      id: const ProductId('product-1'),
      tenantId: const TenantId('tenant-1'),
      referenceId: ProductReferenceId('SP-0001'),
      name: ProductName('Thuốc A'),
      actorId: 'user-1',
      baseUnit: ProductBaseUnit('Hộp'),
    );

    test('updateProfile changes identity fields and emits event', () {
      final updated = createProduct().updateProfile(
        name: ProductName('Thuốc A 100ml'),
        commercialName: ProductName('Brand A'),
        sku: Sku('SKU-1'),
        actorId: 'user-2',
      );

      expect(updated.name.value, 'Thuốc A 100ml');
      expect(updated.commercialName?.value, 'Brand A');
      expect(updated.sku?.value, 'SKU-1');
      expect(updated.domainEvents!.last, isA<ProductProfileUpdated>());
    });

    test('replaceImages normalizes primary and removes missing_image blocker', () {
      final product = createProduct();
      expect(
        product.readiness.hasBlocker(ReadinessBlockerCode.missingImage),
        isTrue,
      );

      final updated = product.replaceImages(
        images: const [
          ProductImage(storageKey: 'img-1', isPrimary: false, sortOrder: 0),
        ],
        actorId: 'user-2',
      );

      expect(updated.images.single.isPrimary, isTrue);
      expect(
        updated.readiness.hasBlocker(ReadinessBlockerCode.missingImage),
        isFalse,
      );
      expect(updated.domainEvents!.last, isA<ProductImagesReplaced>());
    });

    test('deactivate / reactivate transitions business status', () {
      final deactivated = createProduct().deactivate(actorId: 'user-2');
      expect(deactivated.status, ProductBusinessStatus.inactive);
      expect(deactivated.domainEvents!.last, isA<ProductDeactivated>());

      final reactivated = deactivated.reactivate(actorId: 'user-3');
      expect(reactivated.status, ProductBusinessStatus.active);
      expect(reactivated.domainEvents!.last, isA<ProductReactivated>());
    });

    test('deactivate throws when already inactive', () {
      final inactive = createProduct().deactivate(actorId: 'user-2');
      expect(
        () => inactive.deactivate(actorId: 'user-3'),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('softDelete / restore transitions to soft_deleted then inactive', () {
      final deleted = createProduct().softDelete(actorId: 'user-2');
      expect(deleted.status, ProductBusinessStatus.softDeleted);
      expect(deleted.isSoftDeleted, isTrue);
      expect(deleted.domainEvents!.last, isA<ProductDeleted>());

      final restored = deleted.restore(actorId: 'user-3');
      expect(restored.status, ProductBusinessStatus.inactive);
      expect(restored.isSoftDeleted, isFalse);
      expect(restored.domainEvents!.last, isA<ProductRestored>());
    });

    test('updateProfile throws when soft-deleted', () {
      final deleted = createProduct().softDelete(actorId: 'user-2');
      expect(
        () => deleted.updateProfile(
          name: ProductName('X'),
          actorId: 'user-3',
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });
}
