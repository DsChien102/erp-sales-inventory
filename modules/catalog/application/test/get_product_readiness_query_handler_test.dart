import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

class _FakeReadinessReadPort implements IProductReadinessReadPort {
  ProductReadinessFacts? factsToReturn;

  String? lastTenantId;
  String? lastProductId;

  @override
  Future<ProductReadinessFacts?> loadFacts({
    required String tenantId,
    required String productId,
  }) async {
    lastTenantId = tenantId;
    lastProductId = productId;
    return factsToReturn;
  }
}

void main() {
  group('GetProductReadinessQueryHandler', () {
    test('scn_e02_u03_fr01_01 returns many blockers for minimal facts', () async {
      final port = _FakeReadinessReadPort()
        ..factsToReturn = ProductReadinessFacts.forCreate(
          productId: 'product-1',
          productName: 'Thuốc A',
          hasBaseUnit: false,
          hasImages: false,
        );
      final handler = GetProductReadinessQueryHandler(
        readinessReadPort: port,
        permissionChecker: FakePermissionChecker(),
      );

      final view = await handler.handle(
        GetProductReadinessQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
        ),
      );

      expect(port.lastTenantId, 'tenant-1');
      expect(port.lastProductId, 'product-1');
      expect(view.readinessSummary.status, ReadinessStatus.incomplete);
      expect(
        view.readinessSummary.blockers.map((blocker) => blocker.code),
        contains(ReadinessBlockerCode.missingBaseUnit),
      );
      expect(view.primaryActionId, ContextualActionId.setBaseUnit);
    });

    test('scn_e02_u03_fr03_03 disables price action without pricing permission',
        () async {
      final port = _FakeReadinessReadPort()
        ..factsToReturn = const ProductReadinessFacts(
          productId: 'product-2',
          productName: 'Thuốc B',
          hasBaseUnit: true,
          hasImages: true,
          hasStock: true,
          hasBasePrice: true,
          hasPriceBand: false,
          hasRequiredCustomFields: true,
        );
      final handler = GetProductReadinessQueryHandler(
        readinessReadPort: port,
        permissionChecker: FakePermissionChecker(
          deny: {CatalogPermissions.managePricing},
        ),
      );

      final view = await handler.handle(
        GetProductReadinessQuery(
          tenantId: 'tenant-1',
          productId: 'product-2',
        ),
      );

      final priceAction = view.suggestedActions.singleWhere(
        (action) => action.actionId == ContextualActionId.setPriceBand,
      );
      expect(priceAction.enabled, isFalse);
      expect(
        view.readinessSummary.blockers.map((blocker) => blocker.code),
        contains(ReadinessBlockerCode.missingPriceBand),
      );
    });

    test('scn_e02_u03_fr04_01 refresh reflects completed base unit', () async {
      final port = _FakeReadinessReadPort()
        ..factsToReturn = const ProductReadinessFacts(
          productId: 'product-3',
          productName: 'Thuốc C',
          hasBaseUnit: true,
          hasImages: true,
          hasStock: false,
          hasBasePrice: true,
          hasPriceBand: false,
          hasRequiredCustomFields: true,
        );
      final handler = GetProductReadinessQueryHandler(
        readinessReadPort: port,
        permissionChecker: FakePermissionChecker(),
      );

      final view = await handler.handle(
        GetProductReadinessQuery(
          tenantId: 'tenant-1',
          productId: 'product-3',
        ),
      );

      final unitItem = view.checklist.singleWhere(
        (item) => item.group == ReadinessChecklistGroup.units,
      );
      expect(unitItem.status, ReadinessChecklistItemStatus.complete);
      expect(
        view.readinessSummary.blockers.map((blocker) => blocker.code),
        isNot(contains(ReadinessBlockerCode.missingBaseUnit)),
      );
      expect(
        view.readinessSummary.blockers.map((blocker) => blocker.code),
        contains(ReadinessBlockerCode.missingPriceBand),
      );
    });

    test('throws when product not found', () async {
      final handler = GetProductReadinessQueryHandler(
        readinessReadPort: _FakeReadinessReadPort(),
        permissionChecker: FakePermissionChecker(),
      );

      await expectLater(
        handler.handle(
          GetProductReadinessQuery(
            tenantId: 'tenant-1',
            productId: 'missing',
          ),
        ),
        throwsA(
          isA<ApplicationException>().having(
            (error) => error.message,
            'message',
            'Product not found',
          ),
        ),
      );
    });
  });
}
