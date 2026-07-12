import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../exceptions/missing_base_unit_exception.dart';
import '../exceptions/not_basic_stock_mode_exception.dart';
import '../exceptions/stale_stock_quantity_exception.dart';
import '../ids/product_id.dart';
import 'events/product_stock_adjusted.dart';
import 'rules/base_unit_required_for_stock_rule.dart';
import 'stock_mode.dart';

/// Basic/Advanced stock profile for a product (1:1 with Product).
final class ProductStockProfile extends Entity<ProductId> implements IAggregateRoot {
  ProductStockProfile._({
    required super.id,
    required this.tenantId,
    required this.mode,
    this.basicStockQuantityBase,
  });

  final TenantId tenantId;
  final StockMode mode;

  /// Non-negative integer quantity in base unit (Foundation).
  final int? basicStockQuantityBase;

  /// Snapshot factory for Phase 1–2 gateway passthrough (no load yet).
  factory ProductStockProfile.basic({int? basicStockQuantityBase}) {
    return ProductStockProfile._(
      id: const ProductId('_snapshot'),
      tenantId: const TenantId('_snapshot'),
      mode: StockMode.basic,
      basicStockQuantityBase: basicStockQuantityBase,
    );
  }

  factory ProductStockProfile.advanced() {
    return ProductStockProfile._(
      id: const ProductId('_snapshot'),
      tenantId: const TenantId('_snapshot'),
      mode: StockMode.advanced,
      basicStockQuantityBase: null,
    );
  }

  factory ProductStockProfile.reconstitute({
    required ProductId productId,
    required TenantId tenantId,
    required StockMode mode,
    int? basicStockQuantityBase,
  }) {
    return ProductStockProfile._(
      id: productId,
      tenantId: tenantId,
      mode: mode,
      basicStockQuantityBase: basicStockQuantityBase,
    );
  }

  /// Sets basic stock quantity (guided create / initial set).
  ProductStockProfile setBasicQuantity({
    required int quantity,
    required bool hasBaseUnit,
    required String actorId,
    DateTime? now,
  }) {
    _assertNonNegative(quantity);
    final rule = BaseUnitRequiredForStockRule(hasBaseUnit: hasBaseUnit);
    if (rule.isBroken()) {
      throw MissingBaseUnitException(rule.message);
    }
    if (mode.isAdvanced) {
      throw NotBasicStockModeException();
    }

    final updated = ProductStockProfile._(
      id: id,
      tenantId: tenantId,
      mode: StockMode.basic,
      basicStockQuantityBase: quantity,
    );
    updated.addDomainEvent(
      ProductStockAdjusted(
        productId: id,
        tenantId: tenantId,
        quantity: quantity,
      ),
    );
    return updated;
  }

  /// Adjusts basic stock to an absolute quantity (optimistic concurrency optional).
  ProductStockProfile adjust({
    required int newQuantity,
    required bool hasBaseUnit,
    required String actorId,
    int? expectedQuantity,
    DateTime? now,
  }) {
    _assertNonNegative(newQuantity);
    final rule = BaseUnitRequiredForStockRule(hasBaseUnit: hasBaseUnit);
    if (rule.isBroken()) {
      throw MissingBaseUnitException(rule.message);
    }
    if (mode.isAdvanced) {
      throw NotBasicStockModeException();
    }
    if (expectedQuantity != null && basicStockQuantityBase != expectedQuantity) {
      throw StaleStockQuantityException();
    }

    final updated = ProductStockProfile._(
      id: id,
      tenantId: tenantId,
      mode: StockMode.basic,
      basicStockQuantityBase: newQuantity,
    );
    updated.addDomainEvent(
      ProductStockAdjusted(
        productId: id,
        tenantId: tenantId,
        quantity: newQuantity,
      ),
    );
    return updated;
  }

  ProductStockProfile withBasicStockQuantityBase(int quantity) {
    _assertNonNegative(quantity);
    return ProductStockProfile._(
      id: id,
      tenantId: tenantId,
      mode: mode,
      basicStockQuantityBase: quantity,
    );
  }

  static void _assertNonNegative(int quantity) {
    if (quantity < 0) {
      throw DomainException('Stock quantity must be a non-negative integer.');
    }
  }
}
