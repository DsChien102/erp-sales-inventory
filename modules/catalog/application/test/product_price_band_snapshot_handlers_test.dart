import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

class _FakeProductPriceBandGateway implements IProductPriceBandGateway {
  _FakeProductPriceBandGateway({this.snapshotBuilder});

  final Future<ProductPriceBandSnapshotDto> Function({
    required String tenantId,
    required List<ProductPriceBandSnapshotRequest> items,
  })?
  snapshotBuilder;

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
              listBeforeVat: 120000,
              listBeforeVatMissing: false,
              floorBeforeVat: 95000,
              floorBeforeVatMissing: false,
              floorBeforeVatHidden: false,
              isUnitActive: true,
              productBusinessStatus: ProductBusinessStatus.active,
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
    required int listBeforeVat,
    required int listAfterVat,
    int? floorBeforeVat,
    required PriceBandSourceType sourceType,
    int? floorAfterVat,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    ProductPriceBandStatus? status,
    String? storePriceRuleId,
    double? listMarkupRatio,
    double? floorMarkupRatio,
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
      expect(result.items.single.listBeforeVat, 120000);
      expect(result.items.single.listBeforeVatMissing, isFalse);
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
                listBeforeVatMissing: true,
                floorBeforeVatMissing: true,
                floorBeforeVatHidden: false,
                isUnitActive: true,
                productBusinessStatus: ProductBusinessStatus.active,
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

      expect(result.items.single.listBeforeVatMissing, isTrue);
      expect(result.items.single.listBeforeVat, isNull);
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
                listBeforeVatMissing: true,
                floorBeforeVatMissing: true,
                floorBeforeVatHidden: false,
                isUnitActive: false,
                productBusinessStatus: ProductBusinessStatus.active,
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
      expect(result.items.single.listBeforeVatMissing, isTrue);
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

      expect(result.items.single.floorBeforeVat, 95000);
      expect(result.items.single.floorBeforeVatMissing, isFalse);
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
                listBeforeVat: 100000,
                listBeforeVatMissing: false,
                floorBeforeVatMissing: true,
                floorBeforeVatHidden: false,
                isUnitActive: true,
                productBusinessStatus: ProductBusinessStatus.active,
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

      expect(result.items.single.listBeforeVat, 100000);
      expect(result.items.single.floorBeforeVatMissing, isTrue);
      expect(result.items.single.floorBeforeVat, isNull);
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
