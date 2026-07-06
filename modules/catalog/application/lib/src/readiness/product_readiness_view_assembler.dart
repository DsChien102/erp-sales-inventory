import 'package:vet45_catalog_domain/domain.dart';

import 'contextual_action_dto.dart';
import 'contextual_action_id.dart';
import 'contextual_action_priority.dart';
import 'product_readiness_permission_context.dart';
import 'product_readiness_view_dto.dart';
import 'readiness_blocker_dto.dart';
import 'readiness_checklist_group.dart';
import 'readiness_checklist_item_dto.dart';
import 'readiness_checklist_item_status.dart';
import 'readiness_item_kind.dart';
import 'readiness_summary_dto.dart';

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
    if (facts.stockMode == StockMode.advanced) {
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
          blockerCode: facts.hasStock ? null : ReadinessBlockerCode.pendingStockFromInventory,
          description: 'Nguồn tồn kho từ module Kho',
        ),
      );
      return;
    }

    if (!facts.hasStock && facts.hasBaseUnit && !_hasPrimaryAction(actions)) {
      actions.add(
        ContextualActionDto(
          actionId: ContextualActionId.setInitialStock,
          label: 'Thiết lập tồn kho',
          priority: ContextualActionPriority.primary,
          enabled: permissions.can(CatalogPermissions.manageStock),
          requiredPermission: CatalogPermissions.manageStock,
        ),
      );
    }
    checklist.add(
      ReadinessChecklistItemDto(
        group: ReadinessChecklistGroup.stock,
        label: 'Tồn kho',
        status: facts.hasStock
            ? ReadinessChecklistItemStatus.complete
            : ReadinessChecklistItemStatus.missing,
        kind: ReadinessItemKind.required,
        blockerCode: facts.hasStock ? null : ReadinessBlockerCode.missingStock,
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
