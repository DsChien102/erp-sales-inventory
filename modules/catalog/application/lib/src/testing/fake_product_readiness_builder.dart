import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';

/// Builds [ProductReadinessViewDto] for [FakeCatalogModule] scenarios.
abstract final class FakeProductReadinessBuilder {
  static const stockModeBasic = 'basic';
  static const stockModeAdvanced = 'advanced';
  static const basePriceModeManual = 'manual';
  static const basePriceModeCosting = 'costing_module';

  static ProductReadinessViewDto build({
    required String productId,
    required String productName,
    required bool hasBaseUnit,
    required bool hasImages,
    required bool hasStock,
    required bool hasBasePrice,
    required bool hasPriceBand,
    required bool hasRequiredCustomFields,
    required String stockMode,
    required String basePriceMode,
    bool pricePermissionDenied = false,
  }) {
    final blockers = <ReadinessBlockerDto>[];
    final checklist = <ReadinessChecklistItemDto>[];
    final actions = <ContextualActionDto>[];

    checklist.add(
      ReadinessChecklistItemDto(
        group: ReadinessChecklistGroup.profile,
        label: 'Hồ sơ cơ bản',
        status: ReadinessChecklistItemStatus.complete,
        kind: ReadinessItemKind.required,
      ),
    );

    final imageStatus = hasImages
        ? ReadinessChecklistItemStatus.complete
        : ReadinessChecklistItemStatus.missing;
    if (!hasImages) {
      blockers.add(
        const ReadinessBlockerDto(
          code: ReadinessBlockerCode.missingImage,
          message: 'Chưa có ảnh sản phẩm',
          group: 'profile',
        ),
      );
    }
    checklist.add(
      ReadinessChecklistItemDto(
        group: ReadinessChecklistGroup.images,
        label: 'Ảnh sản phẩm',
        status: imageStatus,
        kind: ReadinessItemKind.recommended,
        blockerCode:
            hasImages ? null : ReadinessBlockerCode.missingImage,
      ),
    );

    final unitStatus = hasBaseUnit
        ? ReadinessChecklistItemStatus.complete
        : ReadinessChecklistItemStatus.missing;
    if (!hasBaseUnit) {
      blockers.add(
        const ReadinessBlockerDto(
          code: ReadinessBlockerCode.missingBaseUnit,
          message: 'Thiếu đơn vị cơ sở',
          group: 'units',
        ),
      );
      actions.add(
        const ContextualActionDto(
          actionId: ContextualActionId.setBaseUnit,
          label: 'Thiết lập đơn vị cơ sở',
          priority: ContextualActionPriority.primary,
          enabled: true,
          requiredPermission: CatalogPermissions.manageUnits,
        ),
      );
    }
    checklist.add(
      ReadinessChecklistItemDto(
        group: ReadinessChecklistGroup.units,
        label: 'Đơn vị cơ sở',
        status: unitStatus,
        kind: ReadinessItemKind.required,
        blockerCode:
            hasBaseUnit ? null : ReadinessBlockerCode.missingBaseUnit,
      ),
    );

    _appendStockDimension(
      blockers: blockers,
      checklist: checklist,
      actions: actions,
      hasStock: hasStock,
      stockMode: stockMode,
      hasBaseUnit: hasBaseUnit,
    );

    _appendBasePriceDimension(
      blockers: blockers,
      checklist: checklist,
      actions: actions,
      hasBasePrice: hasBasePrice,
      basePriceMode: basePriceMode,
      hasBaseUnit: hasBaseUnit,
    );

    _appendPriceBandDimension(
      blockers: blockers,
      checklist: checklist,
      actions: actions,
      hasPriceBand: hasPriceBand,
      hasBaseUnit: hasBaseUnit,
      hasBasePrice: hasBasePrice,
      pricePermissionDenied: pricePermissionDenied,
    );

    _appendCustomFieldsDimension(
      blockers: blockers,
      checklist: checklist,
      actions: actions,
      hasRequiredCustomFields: hasRequiredCustomFields,
    );

    checklist.add(
      const ReadinessChecklistItemDto(
        group: ReadinessChecklistGroup.lifecycle,
        label: 'Trạng thái kinh doanh',
        status: ReadinessChecklistItemStatus.complete,
        kind: ReadinessItemKind.required,
      ),
    );

    final requiredBlockers = blockers.where((b) {
      return b.code != ReadinessBlockerCode.missingImage;
    }).toList(growable: false);

    final status = requiredBlockers.isEmpty
        ? ReadinessStatus.readyToSell
        : ReadinessStatus.incomplete;

    if (status == ReadinessStatus.readyToSell) {
      actions.add(
        const ContextualActionDto(
          actionId: ContextualActionId.createAnotherProduct,
          label: 'Tạo sản phẩm khác',
          priority: ContextualActionPriority.primary,
          enabled: true,
          requiredPermission: CatalogPermissions.create,
        ),
      );
    }

    final primaryActionId = _resolvePrimaryActionId(actions);

    return ProductReadinessViewDto(
      productId: productId,
      productName: productName,
      readinessSummary: ReadinessSummaryDto(
        status: status,
        blockers: blockers,
      ),
      checklist: checklist,
      suggestedActions: actions,
      primaryActionId: primaryActionId,
    );
  }

  static void _appendStockDimension({
    required List<ReadinessBlockerDto> blockers,
    required List<ReadinessChecklistItemDto> checklist,
    required List<ContextualActionDto> actions,
    required bool hasStock,
    required String stockMode,
    required bool hasBaseUnit,
  }) {
    if (stockMode == stockModeAdvanced) {
      if (!hasStock) {
        blockers.add(
          const ReadinessBlockerDto(
            code: ReadinessBlockerCode.pendingStockFromInventory,
            message: 'Chờ dữ liệu tồn kho từ module Kho',
            group: 'stock',
          ),
        );
        if (hasBaseUnit) {
          actions.add(
            const ContextualActionDto(
              actionId: ContextualActionId.openInventory,
              label: 'Xem module Kho',
              priority: ContextualActionPriority.primary,
              enabled: true,
              requiredPermission: CatalogPermissions.viewDetail,
              targetModule: 'inventory',
            ),
          );
        }
      }
      checklist.add(
        ReadinessChecklistItemDto(
          group: ReadinessChecklistGroup.stock,
          label: 'Tồn kho',
          status: hasStock
              ? ReadinessChecklistItemStatus.complete
              : ReadinessChecklistItemStatus.pendingExternal,
          kind: ReadinessItemKind.external,
          blockerCode: hasStock
              ? null
              : ReadinessBlockerCode.pendingStockFromInventory,
          description: 'Nguồn tồn kho từ module Kho',
        ),
      );
      return;
    }

    if (!hasStock) {
      blockers.add(
        const ReadinessBlockerDto(
          code: ReadinessBlockerCode.missingStock,
          message: 'Thiếu tồn kho',
          group: 'stock',
        ),
      );
      if (hasBaseUnit && !_hasPrimaryAction(actions)) {
        actions.add(
          const ContextualActionDto(
            actionId: ContextualActionId.setInitialStock,
            label: 'Thiết lập tồn kho',
            priority: ContextualActionPriority.primary,
            enabled: true,
            requiredPermission: CatalogPermissions.manageStock,
          ),
        );
      }
    }
    checklist.add(
      ReadinessChecklistItemDto(
        group: ReadinessChecklistGroup.stock,
        label: 'Tồn kho',
        status: hasStock
            ? ReadinessChecklistItemStatus.complete
            : ReadinessChecklistItemStatus.missing,
        kind: ReadinessItemKind.required,
        blockerCode: hasStock ? null : ReadinessBlockerCode.missingStock,
      ),
    );
  }

  static void _appendBasePriceDimension({
    required List<ReadinessBlockerDto> blockers,
    required List<ReadinessChecklistItemDto> checklist,
    required List<ContextualActionDto> actions,
    required bool hasBasePrice,
    required String basePriceMode,
    required bool hasBaseUnit,
  }) {
    if (basePriceMode == basePriceModeCosting) {
      if (!hasBasePrice) {
        blockers.add(
          const ReadinessBlockerDto(
            code: ReadinessBlockerCode.pendingBasePriceFromCosting,
            message: 'Chờ Giá cơ sở từ module Giá vốn',
            group: 'pricing',
          ),
        );
        if (hasBaseUnit && !_hasPrimaryAction(actions)) {
          actions.add(
            const ContextualActionDto(
              actionId: ContextualActionId.openCosting,
              label: 'Xem module Giá vốn',
              priority: ContextualActionPriority.primary,
              enabled: true,
              requiredPermission: CatalogPermissions.viewDetail,
              targetModule: 'costing',
            ),
          );
        }
      }
      checklist.add(
        ReadinessChecklistItemDto(
          group: ReadinessChecklistGroup.basePrice,
          label: 'Giá cơ sở định giá',
          status: hasBasePrice
              ? ReadinessChecklistItemStatus.complete
              : ReadinessChecklistItemStatus.pendingExternal,
          kind: ReadinessItemKind.external,
          blockerCode: hasBasePrice
              ? null
              : ReadinessBlockerCode.pendingBasePriceFromCosting,
          description: 'Nguồn giá từ module Giá vốn',
        ),
      );
      return;
    }

    if (!hasBasePrice) {
      blockers.add(
        const ReadinessBlockerDto(
          code: ReadinessBlockerCode.missingPrice,
          message: 'Thiếu Giá cơ sở định giá',
          group: 'pricing',
        ),
      );
      if (hasBaseUnit && !_hasPrimaryAction(actions)) {
        actions.add(
          const ContextualActionDto(
            actionId: ContextualActionId.setManualBasePrice,
            label: 'Thiết lập Giá cơ sở',
            priority: ContextualActionPriority.primary,
            enabled: true,
            requiredPermission: CatalogPermissions.managePricing,
          ),
        );
      }
    }
    checklist.add(
      ReadinessChecklistItemDto(
        group: ReadinessChecklistGroup.basePrice,
        label: 'Giá cơ sở định giá',
        status: hasBasePrice
            ? ReadinessChecklistItemStatus.complete
            : ReadinessChecklistItemStatus.missing,
        kind: ReadinessItemKind.required,
        blockerCode: hasBasePrice ? null : ReadinessBlockerCode.missingPrice,
      ),
    );
  }

  static void _appendPriceBandDimension({
    required List<ReadinessBlockerDto> blockers,
    required List<ReadinessChecklistItemDto> checklist,
    required List<ContextualActionDto> actions,
    required bool hasPriceBand,
    required bool hasBaseUnit,
    required bool hasBasePrice,
    required bool pricePermissionDenied,
  }) {
    if (!hasPriceBand) {
      blockers.add(
        const ReadinessBlockerDto(
          code: ReadinessBlockerCode.missingPriceBand,
          message: 'Thiếu khung giá bán',
          group: 'pricing',
        ),
      );
      if (hasBaseUnit && hasBasePrice) {
        actions.add(
          ContextualActionDto(
            actionId: ContextualActionId.setPriceBand,
            label: 'Thiết lập giá',
            priority: _hasPrimaryAction(actions)
                ? ContextualActionPriority.secondary
                : ContextualActionPriority.primary,
            enabled: !pricePermissionDenied,
            requiredPermission: CatalogPermissions.managePricing,
          ),
        );
      }
    }
    checklist.add(
      ReadinessChecklistItemDto(
        group: ReadinessChecklistGroup.priceBand,
        label: 'Khung giá bán',
        status: hasPriceBand
            ? ReadinessChecklistItemStatus.complete
            : ReadinessChecklistItemStatus.missing,
        kind: ReadinessItemKind.required,
        blockerCode:
            hasPriceBand ? null : ReadinessBlockerCode.missingPriceBand,
      ),
    );
  }

  static void _appendCustomFieldsDimension({
    required List<ReadinessBlockerDto> blockers,
    required List<ReadinessChecklistItemDto> checklist,
    required List<ContextualActionDto> actions,
    required bool hasRequiredCustomFields,
  }) {
    if (!hasRequiredCustomFields) {
      blockers.add(
        const ReadinessBlockerDto(
          code: ReadinessBlockerCode.missingRequiredCustomFields,
          message: 'Thiếu thông tin bổ sung bắt buộc',
          group: 'custom_fields',
        ),
      );
      if (!_hasPrimaryAction(actions)) {
        actions.add(
          const ContextualActionDto(
            actionId: ContextualActionId.fillCustomFields,
            label: 'Nhập thông tin bổ sung',
            priority: ContextualActionPriority.secondary,
            enabled: true,
            requiredPermission: CatalogPermissions.update,
          ),
        );
      }
    }
    checklist.add(
      ReadinessChecklistItemDto(
        group: ReadinessChecklistGroup.customFields,
        label: 'Thông tin bổ sung',
        status: hasRequiredCustomFields
            ? ReadinessChecklistItemStatus.complete
            : ReadinessChecklistItemStatus.missing,
        kind: ReadinessItemKind.required,
        blockerCode: hasRequiredCustomFields
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
