/// Product readiness domain and DTO models.
library;

import 'catalog_enums.dart';

final class ReadinessBlockerDto {
  const ReadinessBlockerDto({
    required this.code,
    required this.message,
    this.group,
  });

  final String code;
  final String message;
  final String? group;

  factory ReadinessBlockerDto.fromJson(Map<String, dynamic> row) {
    return ReadinessBlockerDto(
      code: row['code'] as String,
      message: row['message'] as String,
      group: row['group'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    if (group != null) 'group': group,
  };
}

final class ReadinessSummaryDto {
  const ReadinessSummaryDto({
    required this.status,
    this.blockers = const [],
  });

  final ReadinessStatus status;
  final List<ReadinessBlockerDto> blockers;

  factory ReadinessSummaryDto.fromDomain(ProductReadiness readiness) {
    return ReadinessSummaryDto(
      status: readiness.status,
      blockers: readiness.blockers
          .map(
            (blocker) => ReadinessBlockerDto(
              code: blocker.code,
              message: blocker.message,
              group: blocker.group,
            ),
          )
          .toList(growable: false),
    );
  }

  factory ReadinessSummaryDto.fromRow(Map<String, dynamic> row) {
    final statusWire = row['readiness_status'] as String?;
    final status = switch (statusWire) {
      'ready_to_sell' => ReadinessStatus.readyToSell,
      'ready_to_receive' => ReadinessStatus.readyToReceive,
      _ => ReadinessStatus.incomplete,
    };

    final rawBlockers = row['readiness_blockers'] as List<dynamic>? ?? const [];
    final blockers = rawBlockers.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return ReadinessBlockerDto.fromJson(map);
    }).toList(growable: false);

    return ReadinessSummaryDto(
      status: status,
      blockers: blockers,
    );
  }
}

final class ReadinessBlocker {
  const ReadinessBlocker({
    required this.code,
    required this.message,
    this.group,
  });

  final String code;
  final String message;
  final String? group;

  factory ReadinessBlocker.missingBaseUnit() => const ReadinessBlocker(
    code: ReadinessBlockerCode.missingBaseUnit,
    message: 'Thiếu đơn vị cơ sở',
    group: 'units',
  );

  factory ReadinessBlocker.missingImage() => const ReadinessBlocker(
    code: ReadinessBlockerCode.missingImage,
    message: 'Chưa có ảnh sản phẩm',
    group: 'profile',
  );

  factory ReadinessBlocker.missingPrice() => const ReadinessBlocker(
    code: ReadinessBlockerCode.missingPrice,
    message: 'Thiếu giá',
    group: 'pricing',
  );

  factory ReadinessBlocker.missingPriceBand() => const ReadinessBlocker(
    code: ReadinessBlockerCode.missingPriceBand,
    message: 'Thiếu khung giá bán',
    group: 'pricing',
  );

  factory ReadinessBlocker.missingRequiredCustomFields() => const ReadinessBlocker(
    code: ReadinessBlockerCode.missingRequiredCustomFields,
    message: 'Thiếu thông tin bổ sung bắt buộc',
    group: 'custom_fields',
  );

  factory ReadinessBlocker.pendingBasePriceFromCosting() => const ReadinessBlocker(
    code: ReadinessBlockerCode.pendingBasePriceFromCosting,
    message: 'Chờ Giá cơ sở từ module Giá vốn',
    group: 'pricing',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadinessBlocker &&
          other.code == code &&
          other.message == message &&
          other.group == group);

  @override
  int get hashCode => Object.hash(code, message, group);
}

final class ProductReadiness {
  const ProductReadiness({
    required this.status,
    this.blockers = const [],
  });

  final ReadinessStatus status;
  final List<ReadinessBlocker> blockers;

  bool hasBlocker(String code) => blockers.any((b) => b.code == code);

  ProductReadiness removeBlocker(String code) {
    if (!hasBlocker(code)) return this;
    final newBlockers = blockers.where((b) => b.code != code).toList();
    return ProductReadiness(
      status: newBlockers.isEmpty ? ReadinessStatus.readyToSell : ReadinessStatus.incomplete,
      blockers: List.unmodifiable(newBlockers),
    );
  }

  ProductReadiness addBlocker(ReadinessBlocker blocker) {
    if (hasBlocker(blocker.code)) return this;
    final newBlockers = [...blockers, blocker];
    return ProductReadiness(
      status: ReadinessStatus.incomplete,
      blockers: List.unmodifiable(newBlockers),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductReadiness &&
          other.status == status &&
          _listEquals(other.blockers, blockers));

  @override
  int get hashCode => Object.hash(status, Object.hashAll(blockers));

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

final class ProductReadinessFacts {
  const ProductReadinessFacts({
    required this.productId,
    required this.productName,
    required this.hasBaseUnit,
    required this.hasImages,
    required this.hasStock,
    required this.hasBasePrice,
    required this.hasPriceBand,
    required this.hasRequiredCustomFields,
    this.stockMode = StockMode.basic,
    this.basePriceMode = BasePriceMode.manual,
  });

  final String productId;
  final String productName;
  final bool hasBaseUnit;
  final bool hasImages;
  final bool hasStock;
  final bool hasBasePrice;
  final bool hasPriceBand;
  final bool hasRequiredCustomFields;
  final StockMode stockMode;
  final BasePriceMode basePriceMode;

  factory ProductReadinessFacts.forCreate({
    required String productId,
    required String productName,
    required bool hasBaseUnit,
    required bool hasImages,
  }) {
    return ProductReadinessFacts(
      productId: productId,
      productName: productName,
      hasBaseUnit: hasBaseUnit,
      hasImages: hasImages,
      hasStock: false,
      hasBasePrice: false,
      hasPriceBand: false,
      hasRequiredCustomFields: true,
    );
  }

  factory ProductReadinessFacts.fromRow(Map<String, dynamic> row) {
    return ProductReadinessFacts(
      productId: row['product_id'] as String,
      productName: (row['product_name'] ?? row['name']) as String,
      hasBaseUnit: row['has_base_unit'] as bool? ?? false,
      hasImages: row['has_images'] as bool? ?? false,
      hasStock: row['has_stock'] as bool? ?? false,
      hasBasePrice: row['has_base_price'] as bool? ?? false,
      hasPriceBand: row['has_price_band'] as bool? ?? false,
      hasRequiredCustomFields: row['has_required_custom_fields'] as bool? ?? true,
      stockMode: switch (row['stock_mode'] as String?) {
        'advanced' => StockMode.advanced,
        _ => StockMode.basic,
      },
      basePriceMode: switch (row['base_price_mode'] as String?) {
        'costing_module' => BasePriceMode.costingModule,
        _ => BasePriceMode.manual,
      },
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductReadinessFacts &&
          other.productId == productId &&
          other.productName == productName &&
          other.hasBaseUnit == hasBaseUnit &&
          other.hasImages == hasImages &&
          other.hasStock == hasStock &&
          other.hasBasePrice == hasBasePrice &&
          other.hasPriceBand == hasPriceBand &&
          other.hasRequiredCustomFields == hasRequiredCustomFields &&
          other.stockMode == stockMode &&
          other.basePriceMode == basePriceMode);

  @override
  int get hashCode => Object.hash(
        productId,
        productName,
        hasBaseUnit,
        hasImages,
        hasStock,
        hasBasePrice,
        hasPriceBand,
        hasRequiredCustomFields,
        stockMode,
        basePriceMode,
      );
}

final class ContextualActionDto {
  const ContextualActionDto({
    required this.actionId,
    required this.label,
    required this.priority,
    required this.enabled,
    this.requiredPermission,
    this.targetModule,
  });

  final String actionId;
  final String label;
  final ContextualActionPriority priority;
  final bool enabled;
  final String? requiredPermission;
  final String? targetModule;
}

final class ReadinessChecklistItemDto {
  const ReadinessChecklistItemDto({
    required this.group,
    required this.label,
    required this.status,
    required this.kind,
    this.blockerCode,
    this.description,
  });

  final ReadinessChecklistGroup group;
  final String label;
  final ReadinessChecklistItemStatus status;
  final ReadinessItemKind kind;
  final String? blockerCode;
  final String? description;
}

final class ProductReadinessPermissionContext {
  const ProductReadinessPermissionContext({
    required this.canManageUnits,
    required this.canManageStock,
    required this.canManagePricing,
    required this.canUpdateProduct,
    required this.canCreateProduct,
    required this.canViewDetail,
  });

  final bool canManageUnits;
  final bool canManageStock;
  final bool canManagePricing;
  final bool canUpdateProduct;
  final bool canCreateProduct;
  final bool canViewDetail;

  bool can(String? permissionCode) {
    if (permissionCode == null) {
      return true;
    }
    return switch (permissionCode) {
      'catalog.product.manage_units' => canManageUnits,
      'catalog.product.manage_stock' => canManageStock,
      'catalog.product.manage_pricing' => canManagePricing,
      'catalog.product.update' => canUpdateProduct,
      'catalog.product.create' => canCreateProduct,
      'catalog.product.view_detail' => canViewDetail,
      _ => false,
    };
  }
}

final class ProductReadinessViewDto {
  const ProductReadinessViewDto({
    required this.productId,
    required this.productName,
    required this.readinessSummary,
    this.checklist = const [],
    this.suggestedActions = const [],
    this.primaryActionId,
  });

  final String productId;
  final String productName;
  final ReadinessSummaryDto readinessSummary;
  final List<ReadinessChecklistItemDto> checklist;
  final List<ContextualActionDto> suggestedActions;
  final String? primaryActionId;
}

