import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

class _FakeProductPriceBandGateway implements IProductPriceBandGateway {
  _FakeProductPriceBandGateway({this.snapshotBuilder});

  final Future<ProductPriceBandSnapshotDto> Function({
    required String tenantId,
    required List<ProductPriceBandSnapshotRequest> items,
  })? snapshotBuilder;

  List<ProductPriceBandSnapshotRequest>? lastSnapshotItems;

  @override
  Future<ProductPriceBandSnapshotDto> getPriceBandSnapshot({
    required String tenantId,
    required List<ProductPriceBandSnapshotRequest> items,
  }) async {
    lastSnapshotItems = items;
    if (snapshotBuilder != null) {
      return snapshotBuilder!(tenantId: tenantId, items: items);
    }

    return ProductPriceBandSnapshotDto(
      items: items
          .map(
            (item) => ProductPriceBandSnapshotItemDto(
              productId: item.productId,
              productUnitId: item.productUnitId,
              unitName: 'Lọ',
              currency: 'VND',
              listPrice: 120000,
              listPriceMissing: false,
              floorPrice: 95000,
              floorPriceMissing: false,
              floorPriceHidden: false,
              isUnitActive: true,
              productBusinessStatus: ProductStatus.active,
              capturedAt: DateTime.utc(1970),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<ProductUnitPriceBandsDto> listProductUnitPriceBands({
    required String tenantId,
    required String productId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> setProductUnitPriceBand({
    required String tenantId,
    required String productId,
    required String productUnitId,
    required double listPrice,
    required double floorPrice,
    required PriceBandSourceType sourceType,
    String? storePriceRuleId,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('EPIC-06 / US-04 price band snapshot handlers', () {
    test('scn_e06_u04_fr01_01 returns list price snapshot', () async {
      final gateway = _FakeProductPriceBandGateway();
      final handler = GetProductPriceBandSnapshotQueryHandler(
        priceBandGateway: gateway,
      );

      final result = await handler.handle(
        GetProductPriceBandSnapshotQuery(
          tenantId: 'tenant-1',
          items: const [
            ProductPriceBandSnapshotRequest(
              productId: 'product-1',
              productUnitId: 'product-1-base',
            ),
          ],
        ),
      );

      expect(result.items, hasLength(1));
      expect(result.items.single.listPrice, 120000);
      expect(result.items.single.listPriceMissing, isFalse);
      expect(gateway.lastSnapshotItems?.single.productId, 'product-1');
    });

    test('scn_e06_u04_fr01_03 propagates missing list price from gateway', () async {
      final gateway = _FakeProductPriceBandGateway(
        snapshotBuilder: ({required tenantId, required items}) async {
          return ProductPriceBandSnapshotDto(
            items: [
              ProductPriceBandSnapshotItemDto(
                productId: items.single.productId,
                productUnitId: items.single.productUnitId,
                unitName: 'Lọ',
                currency: 'VND',
                listPriceMissing: true,
                floorPriceMissing: true,
                floorPriceHidden: false,
                isUnitActive: true,
                productBusinessStatus: ProductStatus.active,
                capturedAt: DateTime.utc(1970),
              ),
            ],
          );
        },
      );
      final handler = GetProductPriceBandSnapshotQueryHandler(
        priceBandGateway: gateway,
      );

      final result = await handler.handle(
        GetProductPriceBandSnapshotQuery(
          tenantId: 'tenant-1',
          items: const [
            ProductPriceBandSnapshotRequest(
              productId: 'product-9',
              productUnitId: 'product-9-base',
            ),
          ],
        ),
      );

      expect(result.items.single.listPriceMissing, isTrue);
      expect(result.items.single.listPrice, isNull);
    });

    test('scn_e06_u04_fr01_02 propagates inactive unit', () async {
      final gateway = _FakeProductPriceBandGateway(
        snapshotBuilder: ({required tenantId, required items}) async {
          return ProductPriceBandSnapshotDto(
            items: [
              ProductPriceBandSnapshotItemDto(
                productId: items.single.productId,
                productUnitId: items.single.productUnitId,
                unitName: 'Thùng',
                currency: 'VND',
                listPriceMissing: true,
                floorPriceMissing: true,
                floorPriceHidden: false,
                isUnitActive: false,
                productBusinessStatus: ProductStatus.active,
                capturedAt: DateTime.utc(1970),
              ),
            ],
          );
        },
      );
      final handler = GetProductPriceBandSnapshotQueryHandler(
        priceBandGateway: gateway,
      );

      final result = await handler.handle(
        GetProductPriceBandSnapshotQuery(
          tenantId: 'tenant-1',
          items: const [
            ProductPriceBandSnapshotRequest(
              productId: 'product-1',
              productUnitId: 'product-1-unit-thung',
            ),
          ],
        ),
      );

      expect(result.items.single.isUnitActive, isFalse);
      expect(result.items.single.listPriceMissing, isTrue);
    });

    test('scn_e06_u04_fr02_01 returns floor price', () async {
      final gateway = _FakeProductPriceBandGateway();
      final handler = GetProductPriceBandSnapshotQueryHandler(
        priceBandGateway: gateway,
      );

      final result = await handler.handle(
        GetProductPriceBandSnapshotQuery(
          tenantId: 'tenant-1',
          items: const [
            ProductPriceBandSnapshotRequest(
              productId: 'product-1',
              productUnitId: 'product-1-base',
            ),
          ],
        ),
      );

      expect(result.items.single.floorPrice, 95000);
      expect(result.items.single.floorPriceMissing, isFalse);
    });

    test('scn_e06_u04_fr02_03 propagates missing floor price', () async {
      final gateway = _FakeProductPriceBandGateway(
        snapshotBuilder: ({required tenantId, required items}) async {
          return ProductPriceBandSnapshotDto(
            items: [
              ProductPriceBandSnapshotItemDto(
                productId: items.single.productId,
                productUnitId: items.single.productUnitId,
                unitName: 'Lọ',
                currency: 'VND',
                listPrice: 100000,
                listPriceMissing: false,
                floorPriceMissing: true,
                floorPriceHidden: false,
                isUnitActive: true,
                productBusinessStatus: ProductStatus.active,
                capturedAt: DateTime.utc(1970),
              ),
            ],
          );
        },
      );
      final handler = GetProductPriceBandSnapshotQueryHandler(
        priceBandGateway: gateway,
      );

      final result = await handler.handle(
        GetProductPriceBandSnapshotQuery(
          tenantId: 'tenant-1',
          items: const [
            ProductPriceBandSnapshotRequest(
              productId: 'product-snapshot-partial',
              productUnitId: 'product-snapshot-partial-base',
            ),
          ],
        ),
      );

      expect(result.items.single.listPrice, 100000);
      expect(result.items.single.floorPriceMissing, isTrue);
      expect(result.items.single.floorPrice, isNull);
    });

    test('scn_e06_u04_fr04_01 sets capturedAt after gateway read', () async {
      final gateway = _FakeProductPriceBandGateway();
      final handler = GetProductPriceBandSnapshotQueryHandler(
        priceBandGateway: gateway,
      );
      final before = DateTime.now().toUtc();

      final result = await handler.handle(
        GetProductPriceBandSnapshotQuery(
          tenantId: 'tenant-1',
          items: const [
            ProductPriceBandSnapshotRequest(
              productId: 'product-1',
              productUnitId: 'product-1-base',
            ),
          ],
        ),
      );

      final after = DateTime.now().toUtc();
      final capturedAt = result.items.single.capturedAt;
      expect(
        capturedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        capturedAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
      expect(result.items.single.productId, 'product-1');
      expect(result.items.single.unitName, 'Lọ');
      expect(result.items.single.currency, 'VND');
    });

    test('scn_e06_u04_validation rejects invalid query', () async {
      final validator = GetProductPriceBandSnapshotQueryValidator();

      await expectLater(
        validator.validate(
          GetProductPriceBandSnapshotQuery(
            tenantId: 'tenant-1',
            items: const [],
          ),
        ),
        throwsA(isA<ValidationException>()),
      );

      await expectLater(
        validator.validate(
          GetProductPriceBandSnapshotQuery(
            tenantId: 'tenant-1',
            items: List.generate(
              101,
              (index) => ProductPriceBandSnapshotRequest(
                productId: 'product-$index',
                productUnitId: 'unit-$index',
              ),
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );

      await expectLater(
        validator.validate(
          GetProductPriceBandSnapshotQuery(
            tenantId: 'tenant-1',
            items: const [
              ProductPriceBandSnapshotRequest(
                productId: 'product-1',
                productUnitId: 'unit-1',
              ),
              ProductPriceBandSnapshotRequest(
                productId: 'product-1',
                productUnitId: 'unit-1',
              ),
            ],
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
