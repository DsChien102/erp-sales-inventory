import 'package:test/test.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('Product Operational Data (US-02)', () {
    test('setInitialStock throws MissingBaseUnitException when baseUnit is null (BR-03)', () {
      final product = Product.create(
        id: const ProductId('p-1'),
        tenantId: const TenantId('tenant-1'),
        name: ProductName('Thuốc A'),
        actorId: 'user-1',
      );

      expect(
        () => product.setInitialStock(
          quantity: 100.0,
          mode: StockMode.basic,
          actorId: 'user-1',
        ),
        throwsA(isA<MissingBaseUnitException>()),
      );
    });

    test('setInitialStock throws NotBasicStockModeException when mode is advanced', () {
      final product = Product.create(
        id: const ProductId('p-2'),
        tenantId: const TenantId('tenant-1'),
        name: ProductName('Thuốc B'),
        actorId: 'user-1',
        baseUnit: ProductBaseUnit('Hộp'),
      );

      expect(
        () => product.setInitialStock(
          quantity: 100.0,
          mode: StockMode.advanced,
          actorId: 'user-1',
        ),
        throwsA(isA<NotBasicStockModeException>()),
      );
    });

    test('setInitialStock sets basic stock profile and removes missing_stock blocker', () {
      final product = Product.create(
        id: const ProductId('p-3'),
        tenantId: const TenantId('tenant-1'),
        name: ProductName('Thuốc C'),
        actorId: 'user-1',
        baseUnit: ProductBaseUnit('Lọ'),
      );

      expect(product.readiness.hasBlocker(ReadinessBlockerCode.missingStock), isTrue);

      final updated = product.setInitialStock(
        quantity: 50.0,
        mode: StockMode.basic,
        actorId: 'user-2',
      );

      expect(updated.stockProfile?.mode, StockMode.basic);
      expect(updated.stockProfile?.initialStock, 50.0);
      expect(updated.readiness.hasBlocker(ReadinessBlockerCode.missingStock), isFalse);
      expect(updated.domainEvents!.last, isA<ProductStockAdjusted>());
      expect((updated.domainEvents!.last as ProductStockAdjusted).quantity, 50.0);
    });

    test('setManualBasePrice throws NotManualBasePriceModeException when mode is costingModule', () {
      final product = Product.create(
        id: const ProductId('p-4'),
        tenantId: const TenantId('tenant-1'),
        name: ProductName('Thuốc D'),
        actorId: 'user-1',
      );

      expect(
        () => product.setManualBasePrice(
          basePrice: 80000.0,
          mode: BasePriceMode.costingModule,
          actorId: 'user-1',
        ),
        throwsA(isA<NotManualBasePriceModeException>()),
      );
    });

    test('setManualBasePrice sets profile and removes missing_price blocker', () {
      final product = Product.create(
        id: const ProductId('p-5'),
        tenantId: const TenantId('tenant-1'),
        name: ProductName('Thuốc E'),
        actorId: 'user-1',
      );

      expect(product.readiness.hasBlocker(ReadinessBlockerCode.missingPrice), isTrue);

      final updated = product.setManualBasePrice(
        basePrice: 120000.0,
        mode: BasePriceMode.manual,
        actorId: 'user-2',
      );

      expect(updated.basePriceProfile?.mode, BasePriceMode.manual);
      expect(updated.basePriceProfile?.basePrice?.amount, 120000.0);
      expect(updated.readiness.hasBlocker(ReadinessBlockerCode.missingPrice), isFalse);
      expect(updated.domainEvents!.last, isA<ProductBasePriceUpdated>());
    });

    test('setInitialPriceBand throws FloorPriceGreaterThanListPriceException when floor > list (BR-04)', () {
      final product = Product.create(
        id: const ProductId('p-6'),
        tenantId: const TenantId('tenant-1'),
        name: ProductName('Thuốc F'),
        actorId: 'user-1',
      );

      expect(
        () => product.setInitialPriceBand(
          productUnitId: 'unit-1',
          listPrice: 100000.0,
          floorPrice: 150000.0,
          actorId: 'user-1',
        ),
        throwsA(isA<FloorPriceGreaterThanListPriceException>()),
      );
    });

    test('setInitialPriceBand sets price band and removes missing_price_band blocker', () {
      final product = Product.create(
        id: const ProductId('p-7'),
        tenantId: const TenantId('tenant-1'),
        name: ProductName('Thuốc G'),
        actorId: 'user-1',
      );

      expect(product.readiness.hasBlocker(ReadinessBlockerCode.missingPriceBand), isTrue);

      final updated = product.setInitialPriceBand(
        productUnitId: 'unit-1',
        listPrice: 200000.0,
        floorPrice: 180000.0,
        actorId: 'user-2',
      );

      expect(updated.priceBands, hasLength(1));
      expect(updated.priceBands.first.listPrice?.amount, 200000.0);
      expect(updated.priceBands.first.floorPrice?.amount, 180000.0);
      expect(updated.readiness.hasBlocker(ReadinessBlockerCode.missingPriceBand), isFalse);
      expect(updated.domainEvents!.last, isA<ProductPriceBandChanged>());
    });

    test('full operational setup transitions readiness to readyToSell when images and baseUnit exist', () {
      final product = Product.create(
        id: const ProductId('p-8'),
        tenantId: const TenantId('tenant-1'),
        name: ProductName('Thuốc H'),
        actorId: 'user-1',
        baseUnit: ProductBaseUnit('Hộp'),
        images: const [
          ProductImage(storageKey: 'img-1', isPrimary: true, sortOrder: 0),
        ],
      );

      expect(product.readiness.status, ReadinessStatus.incomplete);

      final withStock = product.setInitialStock(
        quantity: 100.0,
        mode: StockMode.basic,
        actorId: 'user-1',
      );
      expect(withStock.readiness.status, ReadinessStatus.incomplete);

      final withPrice = withStock.setManualBasePrice(
        basePrice: 50000.0,
        mode: BasePriceMode.manual,
        actorId: 'user-1',
      );
      expect(withPrice.readiness.status, ReadinessStatus.incomplete);

      final withBand = withPrice.setInitialPriceBand(
        productUnitId: 'unit-1',
        listPrice: 70000.0,
        floorPrice: 60000.0,
        actorId: 'user-1',
      );

      expect(withBand.readiness.status, ReadinessStatus.readyToSell);
      expect(withBand.readiness.blockers, isEmpty);
    });
  });
}
