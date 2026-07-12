import 'package:test/test.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('ProductStockProfile', () {
    test('setBasicQuantity throws when base unit missing', () {
      final profile = ProductStockProfile.reconstitute(
        productId: const ProductId('p-1'),
        tenantId: const TenantId('tenant-1'),
        mode: StockMode.basic,
      );

      expect(
        () => profile.setBasicQuantity(
          quantity: 100,
          hasBaseUnit: false,
          actorId: 'user-1',
        ),
        throwsA(isA<MissingBaseUnitException>()),
      );
    });

    test('setBasicQuantity throws when mode is advanced', () {
      final profile = ProductStockProfile.reconstitute(
        productId: const ProductId('p-2'),
        tenantId: const TenantId('tenant-1'),
        mode: StockMode.advanced,
      );

      expect(
        () => profile.setBasicQuantity(
          quantity: 100,
          hasBaseUnit: true,
          actorId: 'user-1',
        ),
        throwsA(isA<NotBasicStockModeException>()),
      );
    });

    test('setBasicQuantity sets quantity and emits event', () {
      final profile = ProductStockProfile.reconstitute(
        productId: const ProductId('p-3'),
        tenantId: const TenantId('tenant-1'),
        mode: StockMode.basic,
      );

      final updated = profile.setBasicQuantity(
        quantity: 50,
        hasBaseUnit: true,
        actorId: 'user-2',
      );

      expect(updated.mode, StockMode.basic);
      expect(updated.basicStockQuantityBase, 50);
      expect(updated.domainEvents!.last, isA<ProductStockAdjusted>());
      expect((updated.domainEvents!.last as ProductStockAdjusted).quantity, 50);
    });

    test('adjust throws StaleStockQuantityException on mismatch', () {
      final profile = ProductStockProfile.reconstitute(
        productId: const ProductId('p-4'),
        tenantId: const TenantId('tenant-1'),
        mode: StockMode.basic,
        basicStockQuantityBase: 10,
      );

      expect(
        () => profile.adjust(
          newQuantity: 20,
          hasBaseUnit: true,
          actorId: 'user-1',
          expectedQuantity: 11,
        ),
        throwsA(isA<StaleStockQuantityException>()),
      );
    });

    test('adjust updates quantity when expected matches', () {
      final profile = ProductStockProfile.reconstitute(
        productId: const ProductId('p-5'),
        tenantId: const TenantId('tenant-1'),
        mode: StockMode.basic,
        basicStockQuantityBase: 10,
      );

      final updated = profile.adjust(
        newQuantity: 20,
        hasBaseUnit: true,
        actorId: 'user-1',
        expectedQuantity: 10,
      );

      expect(updated.basicStockQuantityBase, 20);
      expect(updated.domainEvents!.last, isA<ProductStockAdjusted>());
    });
  });

  group('ProductBasePriceProfile', () {
    test('setManual throws when mode is costingModule', () {
      final profile = ProductBasePriceProfile.reconstitute(
        productId: const ProductId('p-6'),
        tenantId: const TenantId('tenant-1'),
        mode: BasePriceMode.costingModule,
      );

      expect(
        () => profile.setManual(amount: 80000, actorId: 'user-1'),
        throwsA(isA<NotManualBasePriceModeException>()),
      );
    });

    test('setManual sets base price and emits event', () {
      final profile = ProductBasePriceProfile.reconstitute(
        productId: const ProductId('p-7'),
        tenantId: const TenantId('tenant-1'),
        mode: BasePriceMode.manual,
      );

      final updated = profile.setManual(amount: 120000, actorId: 'user-2');

      expect(updated.mode, BasePriceMode.manual);
      expect(updated.basePrice?.amount, 120000.0);
      expect(updated.domainEvents!.last, isA<ProductBasePriceUpdated>());
    });
  });

  group('ProductUnitPriceBand', () {
    test('set throws when floor > list', () {
      expect(
        () => ProductUnitPriceBand.set(
          id: 'band-1',
          tenantId: const TenantId('tenant-1'),
          productId: const ProductId('p-8'),
          productUnitId: 'unit-1',
          listPrice: 100000,
          floorPrice: 150000,
        ),
        throwsA(isA<FloorPriceGreaterThanListPriceException>()),
      );
    });

    test('set creates band and emits event', () {
      final band = ProductUnitPriceBand.set(
        id: 'band-2',
        tenantId: const TenantId('tenant-1'),
        productId: const ProductId('p-9'),
        productUnitId: 'unit-1',
        listPrice: 200000,
        floorPrice: 180000,
      );

      expect(band.listPrice?.amount, 200000.0);
      expect(band.floorPrice?.amount, 180000.0);
      expect(band.domainEvents!.last, isA<ProductPriceBandChanged>());
    });
  });

  group('snapshot factories remain usable for gateway passthrough', () {
    test('ProductStockProfile.basic exposes mode and basicStockQuantityBase', () {
      final profile = ProductStockProfile.basic(basicStockQuantityBase: 12);
      expect(profile.mode, StockMode.basic);
      expect(profile.basicStockQuantityBase, 12);
    });

    test('ProductBasePriceProfile.manual exposes mode and basePrice', () {
      final profile = ProductBasePriceProfile.manual(
        basePrice: const BasePrice(amount: 1000),
      );
      expect(profile.mode, BasePriceMode.manual);
      expect(profile.basePrice?.amount, 1000);
    });
  });
}
