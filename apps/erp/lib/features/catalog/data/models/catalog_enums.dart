/// Catalog enums and status objects.
library;

/// Business lifecycle status for a product (source of truth for soft delete).
final class ProductBusinessStatus {
  const ProductBusinessStatus._(this._wire);

  static const ProductBusinessStatus active = ProductBusinessStatus._('active');
  static const ProductBusinessStatus inactive = ProductBusinessStatus._('inactive');
  static const ProductBusinessStatus softDeleted = ProductBusinessStatus._('soft_deleted');

  static const List<ProductBusinessStatus> values = [
    active,
    inactive,
    softDeleted,
  ];

  final String _wire;

  bool get isActive => this == active;
  bool get isInactive => this == inactive;
  bool get isSoftDeleted => this == softDeleted;

  String toWire() => _wire;

  /// Dart identifier-style name for sorting/logging (`softDeleted`, not wire).
  String get name => switch (_wire) {
    'active' => 'active',
    'inactive' => 'inactive',
    'soft_deleted' => 'softDeleted',
    _ => _wire,
  };

  factory ProductBusinessStatus.fromWire(String? raw) {
    final wire = (raw ?? '').trim().toLowerCase();
    return switch (wire) {
      'active' => active,
      'inactive' => inactive,
      'soft_deleted' || 'softdeleted' => softDeleted,
      _ => throw ArgumentError('Unsupported product business status: ${raw ?? '(null)'}.'),
    };
  }

  /// Lenient parse for RPC rows; unknown → [active].
  static ProductBusinessStatus tryFromWire(String? raw) {
    try {
      return ProductBusinessStatus.fromWire(raw);
    } catch (_) {
      return active;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ProductBusinessStatus && other._wire == _wire);

  @override
  int get hashCode => _wire.hashCode;

  @override
  String toString() => 'ProductBusinessStatus.$_wire';
}

/// Lifecycle status for a product unit price band.
final class ProductPriceBandStatus {
  const ProductPriceBandStatus._(this._wire);

  static const ProductPriceBandStatus active = ProductPriceBandStatus._('active');
  static const ProductPriceBandStatus inactive = ProductPriceBandStatus._('inactive');
  static const ProductPriceBandStatus deleted = ProductPriceBandStatus._('deleted');

  static const List<ProductPriceBandStatus> values = [
    active,
    inactive,
    deleted,
  ];

  final String _wire;

  bool get isActive => this == active;
  bool get isInactive => this == inactive;
  bool get isDeleted => this == deleted;

  String toWire() => _wire;

  String get name => _wire;

  factory ProductPriceBandStatus.fromWire(String? raw) {
    final wire = (raw ?? '').trim().toLowerCase();
    return switch (wire) {
      'active' => active,
      'inactive' => inactive,
      'deleted' => deleted,
      _ => throw ArgumentError('Unsupported product price band status: ${raw ?? '(null)'}.'),
    };
  }

  static ProductPriceBandStatus tryFromWire(String? raw) {
    try {
      return ProductPriceBandStatus.fromWire(raw);
    } catch (_) {
      return active;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ProductPriceBandStatus && other._wire == _wire);

  @override
  int get hashCode => _wire.hashCode;

  @override
  String toString() => 'ProductPriceBandStatus.$_wire';
}

/// Product readiness status (separate from business/lifecycle status).
enum ReadinessStatus {
  incomplete,
  readyToSell,
  readyToReceive,
}

enum BasePriceMode {
  manual,
  costingModule;

  bool get isManual => this == BasePriceMode.manual;
  bool get isCostingModule => this == BasePriceMode.costingModule;
}

enum StockMode {
  basic,
  advanced;

  bool get isBasic => this == StockMode.basic;
  bool get isAdvanced => this == StockMode.advanced;
}

/// Field that matched an existing product during SKU/barcode duplicate check.
enum ProductDuplicateField {
  sku,
  barcode,
}

/// Readiness filter for product list search (EPIC-01/US-01).
enum ProductReadinessFilter {
  readyToSell,
  incomplete,
}

/// Sort order for product list search (EPIC-01/US-01).
enum ProductSortOrder {
  updatedAtDesc,
  relevanceDesc,
}

enum PriceBandSourceType {
  ruleBased,
  customConfig,
  manual,
}

enum StockDataSource {
  basicProfile,
  inventoryModule,
}

/// Business grouping for product change history entries (EPIC-07/US-04).
enum ProductChangeCategory {
  profile,
  images,
  units,
  stock,
  pricing,
  customFields,
  status,
  lifecycle,
  other;

  String get wireValue => switch (this) {
    ProductChangeCategory.profile => 'profile',
    ProductChangeCategory.images => 'images',
    ProductChangeCategory.units => 'units',
    ProductChangeCategory.stock => 'stock',
    ProductChangeCategory.pricing => 'pricing',
    ProductChangeCategory.customFields => 'custom_fields',
    ProductChangeCategory.status => 'status',
    ProductChangeCategory.lifecycle => 'lifecycle',
    ProductChangeCategory.other => 'other',
  };

  static ProductChangeCategory? tryParse(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return switch (value.trim().toLowerCase()) {
      'profile' => ProductChangeCategory.profile,
      'images' => ProductChangeCategory.images,
      'units' => ProductChangeCategory.units,
      'stock' => ProductChangeCategory.stock,
      'pricing' => ProductChangeCategory.pricing,
      'custom_fields' => ProductChangeCategory.customFields,
      'status' => ProductChangeCategory.status,
      'lifecycle' => ProductChangeCategory.lifecycle,
      'other' => ProductChangeCategory.other,
      _ => null,
    };
  }
}

/// Semantic product change-history actions (EPIC-07/US-04).
enum ProductChangeHistoryAction {
  created,
  profileUpdated,
  imagesUpdated,
  unitAdded,
  unitDeactivated,
  unitReactivated,
  unitDeleted,
  baseUnitSet,
  stockUpdated,
  manualBasePriceSet,
  storePriceRuleApplied,
  priceBandUpdated,
  customFieldValuesUpdated,
  statusChanged,
  deactivated,
  reactivated,
  softDeleted,
  restored;

  ProductChangeCategory get category => switch (this) {
    ProductChangeHistoryAction.created ||
    ProductChangeHistoryAction.profileUpdated => ProductChangeCategory.profile,
    ProductChangeHistoryAction.imagesUpdated => ProductChangeCategory.images,
    ProductChangeHistoryAction.unitAdded ||
    ProductChangeHistoryAction.unitDeactivated ||
    ProductChangeHistoryAction.unitReactivated ||
    ProductChangeHistoryAction.unitDeleted ||
    ProductChangeHistoryAction.baseUnitSet => ProductChangeCategory.units,
    ProductChangeHistoryAction.stockUpdated => ProductChangeCategory.stock,
    ProductChangeHistoryAction.manualBasePriceSet ||
    ProductChangeHistoryAction.storePriceRuleApplied ||
    ProductChangeHistoryAction.priceBandUpdated => ProductChangeCategory.pricing,
    ProductChangeHistoryAction.customFieldValuesUpdated => ProductChangeCategory.customFields,
    ProductChangeHistoryAction.statusChanged ||
    ProductChangeHistoryAction.deactivated ||
    ProductChangeHistoryAction.reactivated => ProductChangeCategory.status,
    ProductChangeHistoryAction.softDeleted ||
    ProductChangeHistoryAction.restored => ProductChangeCategory.lifecycle,
  };

  static ProductChangeHistoryAction? tryParse(String? raw) {
    final token = raw?.trim().toLowerCase() ?? '';
    if (token.isEmpty) {
      return null;
    }
    return switch (token) {
      'created' || 'product_created' => ProductChangeHistoryAction.created,
      'update_product_profile' ||
      'product_profile_updated' ||
      'updated_profile' => ProductChangeHistoryAction.profileUpdated,
      'update_product_images' ||
      'product_images_updated' ||
      'updated_images' => ProductChangeHistoryAction.imagesUpdated,
      'add_product_unit' ||
      'add_product_conversion_unit' => ProductChangeHistoryAction.unitAdded,
      'deactivate_product_unit' ||
      'deactivate_product_conversion_unit' => ProductChangeHistoryAction.unitDeactivated,
      'reactivate_product_unit' ||
      'reactivate_product_conversion_unit' => ProductChangeHistoryAction.unitReactivated,
      'delete_product_conversion_unit' => ProductChangeHistoryAction.unitDeleted,
      'set_product_base_unit' => ProductChangeHistoryAction.baseUnitSet,
      'set_basic_stock_quantity_base' ||
      'set_initial_stock' ||
      'adjust_basic_stock' => ProductChangeHistoryAction.stockUpdated,
      'set_manual_base_price' => ProductChangeHistoryAction.manualBasePriceSet,
      'apply_store_price_rule' => ProductChangeHistoryAction.storePriceRuleApplied,
      'set_product_unit_price_band' ||
      'set_initial_price_band' ||
      'recalculate_product_unit_price_band' => ProductChangeHistoryAction.priceBandUpdated,
      'upsert_custom_field_values' ||
      'custom_field_values_updated' => ProductChangeHistoryAction.customFieldValuesUpdated,
      'product_status_changed' => ProductChangeHistoryAction.statusChanged,
      'deactivate_product' => ProductChangeHistoryAction.deactivated,
      'reactivate_product' => ProductChangeHistoryAction.reactivated,
      'product_soft_deleted' => ProductChangeHistoryAction.softDeleted,
      'product_restored' => ProductChangeHistoryAction.restored,
      _ => null,
    };
  }
}

enum ProductPriceBandHistoryTrigger {
  direct,
  basePriceChanged,
  storeRuleChanged;

  static ProductPriceBandHistoryTrigger? tryParse(String? raw) {
    return switch (raw) {
      'direct' => ProductPriceBandHistoryTrigger.direct,
      'basePriceChanged' => ProductPriceBandHistoryTrigger.basePriceChanged,
      'storeRuleChanged' => ProductPriceBandHistoryTrigger.storeRuleChanged,
      _ => null,
    };
  }
}

enum ProductDeletionIssueSeverity {
  warning,
  blocker,
  recommendation,
}

enum SellableProductResolution {
  sellable,
  notSellable,
  notFound,
}

abstract final class ProductBusinessStatusWarningCode {
  static const hasStock = 'has_stock';
  static const openTransaction = 'open_transaction';
  static const activePromotion = 'active_promotion';
}

abstract final class ReadinessBlockerCode {
  static const missingBaseUnit = 'missing_base_unit';
  static const missingImage = 'missing_image';
  static const missingPrice = 'missing_price';
  static const missingPriceBand = 'missing_price_band';
  static const missingStock = 'missing_stock';
  static const missingRequiredCustomFields = 'missing_required_custom_fields';
  static const pendingStockFromInventory = 'pending_stock_from_inventory';
  static const pendingBasePriceFromCosting = 'pending_base_price_from_costing';
}

abstract final class ContextualActionId {
  static const setBaseUnit = 'set_base_unit';
  static const setBasicStockQuantityBase = 'set_basic_stock_quantity_base';
  static const setManualBasePrice = 'set_manual_base_price';
  static const setPriceBand = 'set_price_band';
  static const fillCustomFields = 'fill_custom_fields';
  static const createAnotherProduct = 'create_another_product';
  static const openInventory = 'open_inventory';
  static const openCosting = 'open_costing';
}

enum ContextualActionPriority {
  primary,
  secondary,
}

enum ReadinessChecklistGroup {
  profile,
  images,
  units,
  stock,
  basePrice,
  priceBand,
  customFields,
  lifecycle,
}

enum ReadinessChecklistItemStatus {
  complete,
  missing,
  notApplicable,
  pendingExternal,
}

enum ReadinessItemKind {
  required,
  recommended,
  external,
}

