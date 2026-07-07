import 'package:erp/core/di/injection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_application/testing.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'catalog_e2e_harness.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('EPIC-06 / US-04 price band snapshot E2E', () {
    test('e2e_e06_u04_fr01_01: mediator returns list price for selling unit', () async {
      await setUpErpCatalogE2E(
        scenario: FakeCatalogScenario.scnContractE06U04Fr01_01,
      );
      final catalog = getIt<ICatalogModule>();

      final result = await catalog.executeQueryAsync(
        GetProductPriceBandSnapshotQuery(
          tenantId: 'tenant-1',
          items: const [
            ProductPriceBandSnapshotRequest(
              productId: 'product-5',
              productUnitId: 'product-5-base',
            ),
          ],
        ),
      );

      expect(result.items, hasLength(1));
      final item = result.items.single;
      expect(item.listPrice, 45000);
      expect(item.listPriceMissing, isFalse);
      expect(item.isUnitActive, isTrue);
      expect(item.productBusinessStatus, ProductStatus.inactive);
    });

    test('e2e_e06_u04_fr02_01: mediator returns floor price for threshold check', () async {
      await setUpErpCatalogE2E(
        scenario: FakeCatalogScenario.scnContractE06U04Fr02_01,
      );
      final catalog = getIt<ICatalogModule>();

      final result = await catalog.executeQueryAsync(
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

      final item = result.items.single;
      expect(item.floorPrice, 95000);
      expect(item.floorPriceMissing, isFalse);
      expect(item.listPrice, 120000);
    });

    test('e2e_e06_u04_fr01_03: mediator reports missing list price explicitly', () async {
      await setUpErpCatalogE2E(
        scenario: FakeCatalogScenario.scnContractE06U04Fr01_03,
      );
      final catalog = getIt<ICatalogModule>();

      final result = await catalog.executeQueryAsync(
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

      final item = result.items.single;
      expect(item.listPriceMissing, isTrue);
      expect(item.listPrice, isNull);
    });

    test('e2e_e06_u04_fr01_02: inactive unit returns without valid prices', () async {
      await setUpErpCatalogE2E(
        scenario: FakeCatalogScenario.scnContractE06U04Fr01_02,
      );
      final catalog = getIt<ICatalogModule>();

      final result = await catalog.executeQueryAsync(
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

      final item = result.items.single;
      expect(item.isUnitActive, isFalse);
      expect(item.listPriceMissing, isTrue);
      expect(item.floorPriceMissing, isTrue);
    });

    test('e2e_e06_u04_fr04_01: snapshot includes capturedAt for Sales copy', () async {
      await setUpErpCatalogE2E(
        scenario: FakeCatalogScenario.scnContractE06U04Fr04_01,
      );
      final catalog = getIt<ICatalogModule>();
      final before = DateTime.now().toUtc();

      final result = await catalog.executeQueryAsync(
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
      final item = result.items.single;
      expect(item.capturedAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(item.capturedAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      expect(item.productId, 'product-1');
      expect(item.productUnitId, 'product-1-base');
      expect(item.unitName, isNotEmpty);
      expect(item.currency, 'VND');
    });

    test('e2e_e06_u04_batch: mediator reads multiple line items in one query', () async {
      await setUpErpCatalogE2E(
        scenario: FakeCatalogScenario.scnContractE06U04Fr01_01,
      );
      final catalog = getIt<ICatalogModule>();

      final result = await catalog.executeQueryAsync(
        GetProductPriceBandSnapshotQuery(
          tenantId: 'tenant-1',
          items: const [
            ProductPriceBandSnapshotRequest(
              productId: 'product-5',
              productUnitId: 'product-5-base',
            ),
            ProductPriceBandSnapshotRequest(
              productId: 'product-1',
              productUnitId: 'product-1-base',
            ),
          ],
        ),
      );

      expect(result.items, hasLength(2));
      expect(
        result.items.map((item) => item.productId),
        containsAll(['product-5', 'product-1']),
      );
    });
  });
}
