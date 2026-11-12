// ignore_for_file: implementation_imports

import 'package:erp/features/catalog/data/models/catalog_enums.dart' as new_enum;
import 'package:erp/features/catalog/data/models/product_change_history.dart' as new_history;
import 'package:erp/features/catalog/data/models/product_control_center.dart' as new_pcc;
import 'package:erp/features/catalog/data/models/product_readiness.dart' as new_readiness;
import 'package:erp/features/catalog/logic/catalog_permissions.dart' as new_perm;
import 'package:erp/features/catalog/logic/product_readiness.dart' as new_logic;
import 'package:erp/features/catalog/logic/product_reference_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('product_readiness', () {
    // 3 permission sets:
    // A: Full permissions
    final allPerms = <String>{
      new_perm.CatalogPermissions.view,
      new_perm.CatalogPermissions.viewDetail,
      new_perm.CatalogPermissions.create,
      new_perm.CatalogPermissions.update,
      new_perm.CatalogPermissions.manageStock,
      new_perm.CatalogPermissions.manageUnits,
      new_perm.CatalogPermissions.managePricing,
      new_perm.CatalogPermissions.manageStatus,
      new_perm.CatalogPermissions.delete,
      new_perm.CatalogPermissions.viewHistory,
      new_perm.CatalogPermissions.manageCustomFields,
      new_perm.CatalogPermissions.manageStorePriceRule,
    };

    // B: Missing manage_pricing
    final permsNoPricing = Set<String>.from(allPerms)..remove(new_perm.CatalogPermissions.managePricing);

    // C: Missing view_history
    final permsNoHistory = Set<String>.from(allPerms)..remove(new_perm.CatalogPermissions.viewHistory);

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

      test('readiness_no_missing_stock: no missing_stock or pending_stock_from_inventory blocker', () {
        final perms = new_logic.readinessPermissionsOf((p) => allPerms.contains(p));

        for (final mode in [new_enum.StockMode.basic, new_enum.StockMode.advanced]) {
          final facts = new_readiness.ProductReadinessFacts(
            productId: 'p-no-stock-${mode.name}',
            productName: 'Product No Stock',
            hasBaseUnit: true,
            hasImages: true,
            hasStock: false,
            hasBasePrice: true,
            hasPriceBand: true,
            hasRequiredCustomFields: true,
            stockMode: mode,
            basePriceMode: new_enum.BasePriceMode.manual,
          );

          final readiness = new_logic.ProductReadinessEvaluator.compute(facts);
          final blockerCodes = readiness.blockers.map((b) => b.code).toList();
          expect(blockerCodes, isNot(anyElement(contains('stock'))));

          final view = new_logic.ProductReadinessViewAssembler.assemble(
            facts: facts,
            readiness: readiness,
            permissions: perms,
          );
          final labelsAndDescriptions = view.checklist
              .expand((c) => [c.label, c.description ?? '', c.blockerCode ?? ''])
              .toList();
          expect(labelsAndDescriptions, isNot(contains('Thiếu tồn kho')));
          expect(labelsAndDescriptions, isNot(contains('Chờ tồn kho từ module Kho')));
          expect(
            view.checklist.map((c) => c.blockerCode ?? ''),
            isNot(anyElement(contains('stock'))),
          );
        }
      });
    });

    group('H7 reference id from UUID', () {
      test('productReferenceIdFromUuid outputs expected 11-char string', () {
        expect(productReferenceIdFromUuid('a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d'), 'PFCFIN45MRF');
        expect(productReferenceIdFromUuid('00000000-0000-0000-0000-000000000000'), 'PG5DQR77XOG');
        expect(productReferenceIdFromUuid('ffffffff-ffff-4fff-bfff-ffffffffffff'), 'PZPGQP367HT');
      });
    });
  });
}
