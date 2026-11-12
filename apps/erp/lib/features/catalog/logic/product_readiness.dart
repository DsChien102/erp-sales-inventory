/// Product readiness evaluation and assembler logic.
library;

import '../data/models/catalog_enums.dart';
import '../data/models/custom_field_filter_option.dart';
import '../data/models/product_control_center.dart';
import '../data/models/product_readiness.dart';
import '../data/models/product_search.dart';
import 'catalog_permissions.dart';

export '../data/models/product_readiness.dart' show ProductReadinessPermissionContext;

/// Resolves permission flags for contextual action `enabled` state.
ProductReadinessPermissionContext readinessPermissionsOf(bool Function(String) can) =>
    ProductReadinessPermissionContext(
      canManageUnits: can(CatalogPermissions.manageUnits),
      canManageStock: can(CatalogPermissions.manageStock),
      canManagePricing: can(CatalogPermissions.managePricing),
      canUpdateProduct: can(CatalogPermissions.update),
      canCreateProduct: can(CatalogPermissions.create),
      canViewDetail: can(CatalogPermissions.viewDetail),
    );

/// Computes [ProductReadiness] from operational facts and tenant modes.
abstract final class ProductReadinessEvaluator {
  static ProductReadiness compute(ProductReadinessFacts facts) {
    final blockers = <ReadinessBlocker>[];

    if (!facts.hasBaseUnit) {
      blockers.add(ReadinessBlocker.missingBaseUnit());
    }
    if (!facts.hasImages) {
      blockers.add(ReadinessBlocker.missingImage());
    }

    _appendBasePriceBlockers(blockers, facts);

    if (!facts.hasPriceBand) {
      blockers.add(ReadinessBlocker.missingPriceBand());
    }
    if (!facts.hasRequiredCustomFields) {
      blockers.add(ReadinessBlocker.missingRequiredCustomFields());
    }

    final requiredBlockers = blockers
        .where((blocker) => blocker.code != ReadinessBlockerCode.missingImage)
        .toList(growable: false);

    return ProductReadiness(
      status: requiredBlockers.isEmpty ? ReadinessStatus.readyToSell : ReadinessStatus.incomplete,
      blockers: List.unmodifiable(blockers),
    );
  }

  static void _appendBasePriceBlockers(
    List<ReadinessBlocker> blockers,
    ProductReadinessFacts facts,
  ) {
    if (facts.basePriceMode == BasePriceMode.costingModule) {
      if (!facts.hasBasePrice) {
        blockers.add(ReadinessBlocker.pendingBasePriceFromCosting());
      }
      return;
    }
    if (!facts.hasBasePrice) {
      blockers.add(ReadinessBlocker.missingPrice());
    }
  }
}

/// Maps domain readiness + facts into [ProductReadinessViewDto] for UI.
abstract final class ProductReadinessViewAssembler {
  static ProductReadinessViewDto assemble({
    required ProductReadinessFacts facts,
    required ProductReadiness readiness,
    required ProductReadinessPermissionContext permissions,
  }) {
    final blockers = readiness.blockers
        .map(
          (blocker) => ReadinessBlockerDto(
            code: blocker.code,
            message: blocker.message,
            group: blocker.group,
          ),
        )
        .toList(growable: false);

    final checklist = <ReadinessChecklistItemDto>[];
    final actions = <ContextualActionDto>[];

    checklist.add(
      const ReadinessChecklistItemDto(
        group: ReadinessChecklistGroup.profile,
        label: 'Hồ sơ cơ bản',
        status: ReadinessChecklistItemStatus.complete,
        kind: ReadinessItemKind.required,
      ),
    );

    _appendImages(checklist, blockers, facts.hasImages);
    _appendUnits(checklist, actions, blockers, facts, permissions);
    _appendStock(checklist, actions, blockers, facts, permissions);
    _appendBasePrice(checklist, actions, blockers, facts, permissions);
    _appendPriceBand(checklist, actions, blockers, facts, permissions);
    _appendCustomFields(checklist, actions, blockers, facts, permissions);

    checklist.add(
      const ReadinessChecklistItemDto(
        group: ReadinessChecklistGroup.lifecycle,
        label: 'Trạng thái kinh doanh',
        status: ReadinessChecklistItemStatus.complete,
        kind: ReadinessItemKind.required,
      ),
    );

    if (readiness.status == ReadinessStatus.readyToSell) {
      actions.add(
        ContextualActionDto(
          actionId: ContextualActionId.createAnotherProduct,
          label: 'Tạo sản phẩm khác',
          priority: ContextualActionPriority.primary,
          enabled: permissions.can(CatalogPermissions.create),
          requiredPermission: CatalogPermissions.create,
        ),
      );
    }

    return ProductReadinessViewDto(
      productId: facts.productId,
      productName: facts.productName,
      readinessSummary: ReadinessSummaryDto(
        status: readiness.status,
        blockers: blockers,
      ),
      checklist: checklist,
      suggestedActions: actions,
      primaryActionId: _resolvePrimaryActionId(actions),
    );
  }

  static void _appendImages(
    List<ReadinessChecklistItemDto> checklist,
    List<ReadinessBlockerDto> blockers,
    bool hasImages,
  ) {
    checklist.add(
      ReadinessChecklistItemDto(
        group: ReadinessChecklistGroup.images,
        label: 'Ảnh sản phẩm',
        status: hasImages
            ? ReadinessChecklistItemStatus.complete
            : ReadinessChecklistItemStatus.missing,
        kind: ReadinessItemKind.recommended,
        blockerCode: hasImages ? null : ReadinessBlockerCode.missingImage,
      ),
    );
  }

  static void _appendUnits(
    List<ReadinessChecklistItemDto> checklist,
    List<ContextualActionDto> actions,
    List<ReadinessBlockerDto> blockers,
    ProductReadinessFacts facts,
    ProductReadinessPermissionContext permissions,
  ) {
    if (!facts.hasBaseUnit) {
      actions.add(
        ContextualActionDto(
          actionId: ContextualActionId.setBaseUnit,
          label: 'Thiết lập đơn vị cơ sở',
          priority: ContextualActionPriority.primary,
          enabled: permissions.can(CatalogPermissions.manageUnits),
          requiredPermission: CatalogPermissions.manageUnits,
        ),
      );
    }
    checklist.add(
      ReadinessChecklistItemDto(
        group: ReadinessChecklistGroup.units,
        label: 'Đơn vị cơ sở',
        status: facts.hasBaseUnit
            ? ReadinessChecklistItemStatus.complete
            : ReadinessChecklistItemStatus.missing,
        kind: ReadinessItemKind.required,
        blockerCode: facts.hasBaseUnit ? null : ReadinessBlockerCode.missingBaseUnit,
      ),
    );
  }

  static void _appendStock(
    List<ReadinessChecklistItemDto> checklist,
    List<ContextualActionDto> actions,
    List<ReadinessBlockerDto> blockers,
    ProductReadinessFacts facts,
    ProductReadinessPermissionContext permissions,
  ) {
    if (!facts.hasStock && facts.hasBaseUnit) {
      actions.add(
        ContextualActionDto(
          actionId: ContextualActionId.openInventory,
          label: 'Xem module Kho',
          priority: ContextualActionPriority.primary,
          enabled: permissions.can(CatalogPermissions.viewDetail),
          requiredPermission: CatalogPermissions.viewDetail,
          targetModule: 'inventory',
        ),
      );
    }
    checklist.add(
      ReadinessChecklistItemDto(
        group: ReadinessChecklistGroup.stock,
        label: 'Tồn kho',
        status: facts.hasStock
            ? ReadinessChecklistItemStatus.complete
            : ReadinessChecklistItemStatus.pendingExternal,
        kind: ReadinessItemKind.external,
        description: 'Nguồn tồn kho từ module Kho',
      ),
    );
  }

  static void _appendBasePrice(
    List<ReadinessChecklistItemDto> checklist,
    List<ContextualActionDto> actions,
    List<ReadinessBlockerDto> blockers,
    ProductReadinessFacts facts,
    ProductReadinessPermissionContext permissions,
  ) {
    if (facts.basePriceMode == BasePriceMode.costingModule) {
      if (!facts.hasBasePrice && facts.hasBaseUnit && !_hasPrimaryAction(actions)) {
        actions.add(
          ContextualActionDto(
            actionId: ContextualActionId.openCosting,
            label: 'Xem module Giá vốn',
            priority: ContextualActionPriority.primary,
            enabled: permissions.can(CatalogPermissions.viewDetail),
            requiredPermission: CatalogPermissions.viewDetail,
            targetModule: 'costing',
          ),
        );
      }
      checklist.add(
        ReadinessChecklistItemDto(
          group: ReadinessChecklistGroup.basePrice,
          label: 'Giá cơ sở định giá',
          status: facts.hasBasePrice
              ? ReadinessChecklistItemStatus.complete
              : ReadinessChecklistItemStatus.pendingExternal,
          kind: ReadinessItemKind.external,
          blockerCode: facts.hasBasePrice ? null : ReadinessBlockerCode.pendingBasePriceFromCosting,
          description: 'Nguồn giá từ module Giá vốn',
        ),
      );
      return;
    }

    if (!facts.hasBasePrice && facts.hasBaseUnit && !_hasPrimaryAction(actions)) {
      actions.add(
        ContextualActionDto(
          actionId: ContextualActionId.setManualBasePrice,
          label: 'Thiết lập Giá cơ sở',
          priority: ContextualActionPriority.primary,
          enabled: permissions.can(CatalogPermissions.managePricing),
          requiredPermission: CatalogPermissions.managePricing,
        ),
      );
    }
    checklist.add(
      ReadinessChecklistItemDto(
        group: ReadinessChecklistGroup.basePrice,
        label: 'Giá cơ sở định giá',
        status: facts.hasBasePrice
            ? ReadinessChecklistItemStatus.complete
            : ReadinessChecklistItemStatus.missing,
        kind: ReadinessItemKind.required,
        blockerCode: facts.hasBasePrice ? null : ReadinessBlockerCode.missingPrice,
      ),
    );
  }

  static void _appendPriceBand(
    List<ReadinessChecklistItemDto> checklist,
    List<ContextualActionDto> actions,
    List<ReadinessBlockerDto> blockers,
    ProductReadinessFacts facts,
    ProductReadinessPermissionContext permissions,
  ) {
    if (!facts.hasPriceBand && facts.hasBaseUnit && facts.hasBasePrice) {
      actions.add(
        ContextualActionDto(
          actionId: ContextualActionId.setPriceBand,
          label: 'Thiết lập giá',
          priority: _hasPrimaryAction(actions)
              ? ContextualActionPriority.secondary
              : ContextualActionPriority.primary,
          enabled: permissions.can(CatalogPermissions.managePricing),
          requiredPermission: CatalogPermissions.managePricing,
        ),
      );
    }
    checklist.add(
      ReadinessChecklistItemDto(
        group: ReadinessChecklistGroup.priceBand,
        label: 'Khung giá bán',
        status: facts.hasPriceBand
            ? ReadinessChecklistItemStatus.complete
            : ReadinessChecklistItemStatus.missing,
        kind: ReadinessItemKind.required,
        blockerCode: facts.hasPriceBand ? null : ReadinessBlockerCode.missingPriceBand,
      ),
    );
  }

  static void _appendCustomFields(
    List<ReadinessChecklistItemDto> checklist,
    List<ContextualActionDto> actions,
    List<ReadinessBlockerDto> blockers,
    ProductReadinessFacts facts,
    ProductReadinessPermissionContext permissions,
  ) {
    if (!facts.hasRequiredCustomFields && !_hasPrimaryAction(actions)) {
      actions.add(
        ContextualActionDto(
          actionId: ContextualActionId.fillCustomFields,
          label: 'Nhập thông tin bổ sung',
          priority: ContextualActionPriority.secondary,
          enabled: permissions.can(CatalogPermissions.update),
          requiredPermission: CatalogPermissions.update,
        ),
      );
    }
    checklist.add(
      ReadinessChecklistItemDto(
        group: ReadinessChecklistGroup.customFields,
        label: 'Thông tin bổ sung',
        status: facts.hasRequiredCustomFields
            ? ReadinessChecklistItemStatus.complete
            : ReadinessChecklistItemStatus.missing,
        kind: ReadinessItemKind.required,
        blockerCode: facts.hasRequiredCustomFields
            ? null
            : ReadinessBlockerCode.missingRequiredCustomFields,
      ),
    );
  }

  static bool _hasPrimaryAction(List<ContextualActionDto> actions) {
    return actions.any(
      (action) => action.priority == ContextualActionPriority.primary,
    );
  }

  static String? _resolvePrimaryActionId(List<ContextualActionDto> actions) {
    for (final action in actions) {
      if (action.priority == ContextualActionPriority.primary && action.enabled) {
        return action.actionId;
      }
    }
    for (final action in actions) {
      if (action.enabled) {
        return action.actionId;
      }
    }
    return null;
  }
}

/// Assembles [ProductControlCenterDto] from RPC read model + permissions.
abstract final class ProductControlCenterAssembler {
  static ProductControlCenterDto assemble({
    required ProductControlCenterReadModel model,
    required ProductReadinessPermissionContext permissions,
    bool includeChangeHistory = true,
  }) {
    final readiness = ProductReadinessEvaluator.compute(model.facts);
    final readinessView = ProductReadinessViewAssembler.assemble(
      facts: model.facts,
      readiness: readiness,
      permissions: permissions,
    );

    final hasBaseUnit = model.baseUnitName != null && model.baseUnitName!.trim().isNotEmpty;
    final hasStock = model.stockQuantity != null;
    final hasBasePrice = model.basePriceAmount != null;
    final hasMaterializedPriceBand = model.listBeforeVat != null && model.listAfterVat != null;
    final hasConfiguredPriceBand = model.priceBandSourceType != null;
    final isPendingCustomConfig =
        model.priceBandSourceType == PriceBandSourceType.customConfig && !hasMaterializedPriceBand;

    final filteredCustomFieldGroups = model.customFieldGroupCards
        .map((g) {
          final activeOrHasDataFields = g.fields
              .where((f) => f.isActive || (f.displayValue != null && f.displayValue!.isNotEmpty))
              .toList();
          return CustomFieldGroupCardDto(
            groupId: g.groupId,
            name: customFieldGroupDisplayName(g.name),
            iconKey: g.iconKey,
            sortOrder: g.sortOrder,
            fields: activeOrHasDataFields,
            hasRequiredMissing: activeOrHasDataFields.any((f) => f.isRequired && f.isMissing),
          );
        })
        .where((g) => g.fields.isNotEmpty)
        .toList();

    return ProductControlCenterDto(
      profile: ProductProfileSummaryDto(
        productId: model.productId,
        name: model.name,
        tradeName: model.tradeName,
        sku: model.sku,
        barcode: model.barcode,
        businessStatus: model.businessStatus,
        primaryImageUrl: model.primaryImageUrl,
        images: model.images,
        description: model.description,
        note: model.note,
        trackingMode: model.trackingMode,
        expiryRequired: model.expiryRequired,
        hasInventoryMovements: model.hasInventoryMovements,
      ),
      units: ProductUnitsCardDto(
        baseUnitName: hasBaseUnit ? model.baseUnitName : null,
        conversionUnits: model.conversionUnits,
        isMissing: !hasBaseUnit,
        missingMessage: hasBaseUnit ? null : 'Thiếu đơn vị cơ sở',
      ),
      stock: ProductStockCardDto(
        mode: StockMode.advanced,
        source: StockDataSource.inventoryModule,
        sourceLabel: 'Tồn kho từ module Kho',
        quantity: model.stockQuantity,
        unitName: hasBaseUnit ? model.baseUnitName : null,
        isConfigured: hasStock,
        isOutOfStock: hasStock && model.stockQuantity == 0,
        canAdjust: false,
        currentVersion: model.stockVersion,
        isPendingExternal: false,
        isMissing: false,
        missingMessage: null,
      ),
      basePrice: ProductBasePriceCardDto(
        mode: model.facts.basePriceMode,
        sourceLabel: ProductBasePriceCardDto.sourceLabelFor(model.facts.basePriceMode),
        amount: model.basePriceAmount,
        currency: model.basePriceCurrency,
        baseUnitName: hasBaseUnit ? model.baseUnitName : null,
        canEdit: model.facts.basePriceMode == BasePriceMode.manual,
        isPendingExternal: model.facts.basePriceMode == BasePriceMode.costingModule,
        isMissing: model.facts.basePriceMode == BasePriceMode.manual && !hasBasePrice,
        missingMessage: model.facts.basePriceMode == BasePriceMode.manual && !hasBasePrice
            ? 'Thiếu Giá cơ sở định giá'
            : null,
      ),
      priceBand: ProductPriceBandCardDto(
        listBeforeVat: model.listBeforeVat,
        floorBeforeVat: model.floorBeforeVat,
        listAfterVat: model.listAfterVat,
        floorAfterVat: model.floorAfterVat,
        effectiveFrom: model.priceBandEffectiveFrom,
        effectiveTo: model.priceBandEffectiveTo,
        status: model.priceBandStatus,
        unitName: hasBaseUnit ? model.baseUnitName : null,
        isMissing: !hasConfiguredPriceBand,
        isPendingCalculation: isPendingCustomConfig,
        missingMessage: !hasConfiguredPriceBand ? 'Thiếu khung giá bán' : null,
        sourceType: model.priceBandSourceType,
        storePriceRuleName: model.storePriceRuleName,
        isCustomOverride: model.isCustomOverride,
      ),
      customFieldGroupCards: filteredCustomFieldGroups,
      readinessSummary: ReadinessSummaryDto.fromDomain(readiness),
      checklist: const [],
      contextualActions: readinessView.suggestedActions,
      changeHistoryPreview: includeChangeHistory ? model.changeHistoryPreview : const [],
      primaryActionId: readinessView.primaryActionId,
    );
  }
}

/// Maps search RPC rows to [ProductListItemDto] with computed readiness.
abstract final class ProductListItemAssembler {
  static ProductListItemDto toDto(ProductListItemReadRow row) {
    final readiness = ProductReadinessEvaluator.compute(row.facts);
    final stockLabel = row.stockQuantity?.toString();

    return ProductListItemDto(
      id: row.id,
      name: row.name,
      tradeName: row.tradeName,
      sku: row.sku,
      barcode: row.barcode,
      primaryImageUrl: row.primaryImageUrl,
      businessStatus: row.businessStatus,
      readinessSummary: ReadinessSummaryDto.fromDomain(readiness),
      listBeforeVat: row.listBeforeVat,
      floorBeforeVat: row.floorBeforeVat,
      listAfterVat: row.listAfterVat,
      floorAfterVat: row.floorAfterVat,
      baseUnit: row.baseUnit,
      stockQuantity: row.stockQuantity,
      stockLabel: stockLabel,
      customFieldValues: row.customFieldValues,
      updatedAt: row.updatedAt,
    );
  }
}

