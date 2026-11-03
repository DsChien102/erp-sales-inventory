// ignore_for_file: implementation_imports

import 'package:erp/features/catalog/data/models/catalog_enums.dart' as new_enum;
import 'package:erp/features/catalog/data/models/product_change_history.dart' as new_history;
import 'package:erp/features/catalog/data/models/product_control_center.dart' as new_pcc;
import 'package:erp/features/catalog/data/models/product_readiness.dart' as new_readiness;
import 'package:erp/features/catalog/logic/catalog_permissions.dart' as new_perm;
import 'package:erp/features/catalog/logic/product_readiness.dart' as new_logic;
import 'package:erp/features/catalog/logic/product_reference_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

class _FakePermissionChecker implements IPermissionChecker {
  _FakePermissionChecker(this._allowed);
  final Set<String> _allowed;

  @override
  Future<void> require(String permissionCode) async {
    if (!_allowed.contains(permissionCode)) {
      throw ApplicationException('Forbidden: $permissionCode');
    }
  }
}

void main() {
  group('product_readiness parity', () {
    // 3 sets of facts:
    // 1. Missing base unit
    const factsMissingUnit = ProductReadinessFacts(
      productId: 'p-1',
      productName: 'Product 1',
      hasBaseUnit: false,
      hasImages: true,
      hasStock: false,
      hasBasePrice: false,
      hasPriceBand: false,
      hasRequiredCustomFields: true,
      stockMode: StockMode.basic,
      basePriceMode: BasePriceMode.manual,
    );

    // 2. Complete / ready to sell
    const factsComplete = ProductReadinessFacts(
      productId: 'p-2',
      productName: 'Product 2',
      hasBaseUnit: true,
      hasImages: true,
      hasStock: true,
      hasBasePrice: true,
      hasPriceBand: true,
      hasRequiredCustomFields: true,
      stockMode: StockMode.basic,
      basePriceMode: BasePriceMode.manual,
    );

    // 3. Missing price + missing required custom fields
    const factsMissingPriceAndFields = ProductReadinessFacts(
      productId: 'p-3',
      productName: 'Product 3',
      hasBaseUnit: true,
      hasImages: true,
      hasStock: true,
      hasBasePrice: false,
      hasPriceBand: false,
      hasRequiredCustomFields: false,
      stockMode: StockMode.basic,
      basePriceMode: BasePriceMode.manual,
    );

    // 3 permission sets:
    // A: Full permissions
    final allPerms = <String>{
      CatalogPermissions.view,
      CatalogPermissions.viewDetail,
      CatalogPermissions.create,
      CatalogPermissions.update,
      CatalogPermissions.manageStock,
      CatalogPermissions.manageUnits,
      CatalogPermissions.managePricing,
      CatalogPermissions.manageStatus,
      CatalogPermissions.delete,
      CatalogPermissions.viewHistory,
      CatalogPermissions.manageCustomFields,
      CatalogPermissions.manageStorePriceRule,
    };

    // B: Missing manage_pricing
    final permsNoPricing = Set<String>.from(allPerms)..remove(CatalogPermissions.managePricing);

    // C: Missing view_history
    final permsNoHistory = Set<String>.from(allPerms)..remove(CatalogPermissions.viewHistory);

    group('old (ProductReadinessEvaluator & Assemblers)', () {
      test('computes readiness and assembles view: missing unit', () async {
        final readiness = ProductReadinessEvaluator.compute(factsMissingUnit);
        expect(readiness.status, ReadinessStatus.incomplete);
        expect(readiness.blockers.map((b) => b.code), contains(ReadinessBlockerCode.missingBaseUnit));

        final perms = await ProductReadinessPermissionResolver.resolve(_FakePermissionChecker(allPerms));
        final view = ProductReadinessViewAssembler.assemble(
          facts: factsMissingUnit,
          readiness: readiness,
          permissions: perms,
        );

        expect(view.productId, 'p-1');
        expect(view.readinessSummary.status, ReadinessStatus.incomplete);
        expect(view.suggestedActions.any((a) => a.actionId == ContextualActionId.setBaseUnit), isTrue);
      });

      test('computes readiness and assembles view: complete', () async {
        final readiness = ProductReadinessEvaluator.compute(factsComplete);
        expect(readiness.status, ReadinessStatus.readyToSell);
        expect(readiness.blockers, isEmpty);

        final perms = await ProductReadinessPermissionResolver.resolve(_FakePermissionChecker(allPerms));
        final view = ProductReadinessViewAssembler.assemble(
          facts: factsComplete,
          readiness: readiness,
          permissions: perms,
        );

        expect(view.readinessSummary.status, ReadinessStatus.readyToSell);
        expect(view.suggestedActions.any((a) => a.actionId == ContextualActionId.createAnotherProduct), isTrue);
      });

      test('computes readiness and assembles view: missing price and fields without pricing perm', () async {
        final readiness = ProductReadinessEvaluator.compute(factsMissingPriceAndFields);
        expect(readiness.status, ReadinessStatus.incomplete);
        expect(readiness.blockers.map((b) => b.code), containsAll([
          ReadinessBlockerCode.missingPrice,
          ReadinessBlockerCode.missingPriceBand,
          ReadinessBlockerCode.missingRequiredCustomFields,
        ]));

        final perms = await ProductReadinessPermissionResolver.resolve(_FakePermissionChecker(permsNoPricing));
        final view = ProductReadinessViewAssembler.assemble(
          facts: factsMissingPriceAndFields,
          readiness: readiness,
          permissions: perms,
        );

        expect(view.readinessSummary.status, ReadinessStatus.incomplete);
        // Pricing actions should not be enabled
        final setPriceAction = view.suggestedActions.firstWhere((a) => a.actionId == ContextualActionId.setManualBasePrice);
        expect(setPriceAction.enabled, isFalse);
      });

      test('assembles control center with permissions', () async {
        final model = ProductControlCenterReadModel(
          productId: 'p-1',
          name: 'P1',
          businessStatus: ProductBusinessStatus.active,
          facts: factsMissingUnit,
          changeHistoryPreview: [
            ProductChangeHistoryEntryDto(
              id: 'h1',
              occurredAt: DateTime(2026, 1, 1),
              actorDisplayName: 'Admin',
              changeType: ProductChangeHistoryAction.created,
              summary: 'Created',
            ),
          ],
        );

        final permsWithHistory = await ProductReadinessPermissionResolver.resolve(_FakePermissionChecker(allPerms));
        final canHistory = await ProductReadinessPermissionResolver.canViewHistory(_FakePermissionChecker(allPerms));
        final dtoWithHistory = ProductControlCenterAssembler.assemble(
          model: model,
          permissions: permsWithHistory,
          includeChangeHistory: canHistory,
        );
        expect(dtoWithHistory.changeHistoryPreview, isNotEmpty);

        final permsWithoutHistory = await ProductReadinessPermissionResolver.resolve(_FakePermissionChecker(permsNoHistory));
        final canHistoryNo = await ProductReadinessPermissionResolver.canViewHistory(_FakePermissionChecker(permsNoHistory));
        final dtoNoHistory = ProductControlCenterAssembler.assemble(
          model: model,
          permissions: permsWithoutHistory,
          includeChangeHistory: canHistoryNo,
        );
        expect(dtoNoHistory.changeHistoryPreview, isEmpty);
      });
    });

    group('new (ProductReadinessEvaluator & Assemblers)', () {
      const newFactsMissingUnit = new_readiness.ProductReadinessFacts(
        productId: 'p-1',
        productName: 'Product 1',
        hasBaseUnit: false,
        hasImages: true,
        hasStock: false,
        hasBasePrice: false,
        hasPriceBand: false,
        hasRequiredCustomFields: true,
        stockMode: new_enum.StockMode.basic,
        basePriceMode: new_enum.BasePriceMode.manual,
      );

      const newFactsComplete = new_readiness.ProductReadinessFacts(
        productId: 'p-2',
        productName: 'Product 2',
        hasBaseUnit: true,
        hasImages: true,
        hasStock: true,
        hasBasePrice: true,
        hasPriceBand: true,
        hasRequiredCustomFields: true,
        stockMode: new_enum.StockMode.basic,
        basePriceMode: new_enum.BasePriceMode.manual,
      );

      const newFactsMissingPriceAndFields = new_readiness.ProductReadinessFacts(
        productId: 'p-3',
        productName: 'Product 3',
        hasBaseUnit: true,
        hasImages: true,
        hasStock: true,
        hasBasePrice: false,
        hasPriceBand: false,
        hasRequiredCustomFields: false,
        stockMode: new_enum.StockMode.basic,
        basePriceMode: new_enum.BasePriceMode.manual,
      );

      test('computes readiness and assembles view: missing unit', () {
        final readiness = new_logic.ProductReadinessEvaluator.compute(newFactsMissingUnit);
        expect(readiness.status, new_enum.ReadinessStatus.incomplete);
        expect(
          readiness.blockers.map((b) => b.code),
          contains(new_enum.ReadinessBlockerCode.missingBaseUnit),
        );

        final perms = new_logic.readinessPermissionsOf((p) => allPerms.contains(p));
        final view = new_logic.ProductReadinessViewAssembler.assemble(
          facts: newFactsMissingUnit,
          readiness: readiness,
          permissions: perms,
        );

        expect(view.productId, 'p-1');
        expect(view.readinessSummary.status, new_enum.ReadinessStatus.incomplete);
        expect(
          view.suggestedActions.any((a) => a.actionId == new_enum.ContextualActionId.setBaseUnit),
          isTrue,
        );
      });

      test('computes readiness and assembles view: complete', () {
        final readiness = new_logic.ProductReadinessEvaluator.compute(newFactsComplete);
        expect(readiness.status, new_enum.ReadinessStatus.readyToSell);
        expect(readiness.blockers, isEmpty);

        final perms = new_logic.readinessPermissionsOf((p) => allPerms.contains(p));
        final view = new_logic.ProductReadinessViewAssembler.assemble(
          facts: newFactsComplete,
          readiness: readiness,
          permissions: perms,
        );

        expect(view.readinessSummary.status, new_enum.ReadinessStatus.readyToSell);
        expect(
          view.suggestedActions.any((a) => a.actionId == new_enum.ContextualActionId.createAnotherProduct),
          isTrue,
        );
      });

      test('computes readiness and assembles view: missing price and fields without pricing perm', () {
        final readiness = new_logic.ProductReadinessEvaluator.compute(newFactsMissingPriceAndFields);
        expect(readiness.status, new_enum.ReadinessStatus.incomplete);
        expect(readiness.blockers.map((b) => b.code), containsAll([
          new_enum.ReadinessBlockerCode.missingPrice,
          new_enum.ReadinessBlockerCode.missingPriceBand,
          new_enum.ReadinessBlockerCode.missingRequiredCustomFields,
        ]));

        final perms = new_logic.readinessPermissionsOf((p) => permsNoPricing.contains(p));
        final view = new_logic.ProductReadinessViewAssembler.assemble(
          facts: newFactsMissingPriceAndFields,
          readiness: readiness,
          permissions: perms,
        );

        expect(view.readinessSummary.status, new_enum.ReadinessStatus.incomplete);
        final setPriceAction = view.suggestedActions.firstWhere(
          (a) => a.actionId == new_enum.ContextualActionId.setManualBasePrice,
        );
        expect(setPriceAction.enabled, isFalse);
      });

      test('assembles control center with permissions', () {
        final model = new_pcc.ProductControlCenterReadModel(
          productId: 'p-1',
          name: 'P1',
          businessStatus: new_enum.ProductBusinessStatus.active,
          facts: newFactsMissingUnit,
          changeHistoryPreview: [
            new_history.ProductChangeHistoryEntryDto(
              id: 'h1',
              occurredAt: DateTime(2026, 1, 1),
              actorDisplayName: 'Admin',
              changeType: new_enum.ProductChangeHistoryAction.created,
              summary: 'Created',
            ),
          ],
        );

        final permsWithHistory = new_logic.readinessPermissionsOf((p) => allPerms.contains(p));
        final canHistory = allPerms.contains(new_perm.CatalogPermissions.viewHistory);
        final dtoWithHistory = new_logic.ProductControlCenterAssembler.assemble(
          model: model,
          permissions: permsWithHistory,
          includeChangeHistory: canHistory,
        );
        expect(dtoWithHistory.changeHistoryPreview, isNotEmpty);

        final permsWithoutHistory = new_logic.readinessPermissionsOf((p) => permsNoHistory.contains(p));
        final canHistoryNo = permsNoHistory.contains(new_perm.CatalogPermissions.viewHistory);
        final dtoNoHistory = new_logic.ProductControlCenterAssembler.assemble(
          model: model,
          permissions: permsWithoutHistory,
          includeChangeHistory: canHistoryNo,
        );
        expect(dtoNoHistory.changeHistoryPreview, isEmpty);
      });
    });

    group('H7 reference id from UUID parity', () {
      const uuids = [
        'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
        '00000000-0000-0000-0000-000000000000',
        'ffffffff-ffff-4fff-bfff-ffffffffffff',
      ];

      test('old ProductReferenceId.fromProductId outputs expected string', () {
        final results = uuids.map((u) => ProductReferenceId.fromProductId(ProductId(u)).value).toList();
        for (final res in results) {
          expect(res.startsWith('P'), isTrue);
          expect(res.length, 11);
        }
      });

      test('new productReferenceIdFromUuid outputs exact same result as old implementation', () {
        for (final uuid in uuids) {
          final oldResult = ProductReferenceId.fromProductId(ProductId(uuid)).value;
          final newResult = productReferenceIdFromUuid(uuid);
          expect(newResult, oldResult);
        }
      });
    });
  });
}
