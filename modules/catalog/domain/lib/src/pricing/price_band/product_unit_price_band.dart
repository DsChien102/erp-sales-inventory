import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../exceptions/floor_price_greater_than_list_price_exception.dart';
import '../../ids/product_id.dart';
import '../money.dart';
import 'events/product_price_band_changed.dart';
import 'product_price_band_status.dart';
import 'rules/floor_after_vat_not_greater_than_list_after_vat_rule.dart';
import 'rules/floor_before_vat_not_greater_than_list_before_vat_rule.dart';

/// List + optional floor price band for a product unit (before/after VAT).
final class ProductUnitPriceBand extends Entity<String> implements IAggregateRoot {
  ProductUnitPriceBand({
    required super.id,
    required this.tenantId,
    required this.productId,
    this.productUnitId,
    this.listBeforeVat,
    this.floorBeforeVat,
    this.listAfterVat,
    this.floorAfterVat,
    required this.effectiveFrom,
    this.effectiveTo,
    this.status = ProductPriceBandStatus.active,
    this.storePriceRuleId,
  });

  final String tenantId;
  final String productId;
  final String? productUnitId;
  final Money? listBeforeVat;
  final Money? floorBeforeVat;
  final Money? listAfterVat;
  final Money? floorAfterVat;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final ProductPriceBandStatus status;
  final String? storePriceRuleId;

  /// Complete when list before-VAT and list after-VAT are set; floors optional.
  bool get isComplete => listBeforeVat != null && listAfterVat != null;

  factory ProductUnitPriceBand.set({
    required String id,
    required TenantId tenantId,
    required ProductId productId,
    String? productUnitId,
    required int listBeforeVat,
    required int listAfterVat,
    int? floorBeforeVat,
    int? floorAfterVat,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    ProductPriceBandStatus status = ProductPriceBandStatus.active,
    String? storePriceRuleId,
    String? actorId,
  }) {
    final listBeforeVo = Money(listBeforeVat);
    final listAfterVo = Money(listAfterVat);
    final floorBeforeVo =
        floorBeforeVat == null ? null : Money(floorBeforeVat);
    final floorAfterVo = floorAfterVat == null ? null : Money(floorAfterVat);

    final beforeRule = FloorBeforeVatNotGreaterThanListBeforeVatRule(
      floorBeforeVat: floorBeforeVo,
      listBeforeVat: listBeforeVo,
    );
    if (beforeRule.isBroken()) {
      throw FloorPriceGreaterThanListPriceException(beforeRule.message);
    }

    final afterRule = FloorAfterVatNotGreaterThanListAfterVatRule(
      floorAfterVat: floorAfterVo,
      listAfterVat: listAfterVo,
    );
    if (afterRule.isBroken()) {
      throw FloorPriceGreaterThanListPriceException(afterRule.message);
    }

    final from = effectiveFrom ?? DateTime.now().toUtc();
    final band = ProductUnitPriceBand(
      id: id,
      tenantId: tenantId.value,
      productId: productId.value,
      productUnitId: productUnitId,
      listBeforeVat: listBeforeVo,
      floorBeforeVat: floorBeforeVo,
      listAfterVat: listAfterVo,
      floorAfterVat: floorAfterVo,
      effectiveFrom: from,
      effectiveTo: effectiveTo,
      status: status,
      storePriceRuleId: storePriceRuleId,
    );
    band.addDomainEvent(
      ProductPriceBandChanged(
        productId: productId,
        tenantId: tenantId,
        productUnitId: productUnitId,
        listBeforeVat: listBeforeVat,
        floorBeforeVat: floorBeforeVat,
        listAfterVat: listAfterVat,
        floorAfterVat: floorAfterVat,
        effectiveFrom: from,
        effectiveTo: effectiveTo,
        status: status,
      ),
    );
    return band;
  }

  ProductUnitPriceBand replacePrices({
    required int listBeforeVat,
    required int listAfterVat,
    int? floorBeforeVat,
    int? floorAfterVat,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    ProductPriceBandStatus? status,
    String? storePriceRuleId,
    String? actorId,
  }) {
    return ProductUnitPriceBand.set(
      id: id,
      tenantId: TenantId(tenantId),
      productId: ProductId(productId),
      productUnitId: productUnitId,
      listBeforeVat: listBeforeVat,
      listAfterVat: listAfterVat,
      floorBeforeVat: floorBeforeVat ?? this.floorBeforeVat?.amount,
      floorAfterVat: floorAfterVat ?? this.floorAfterVat?.amount,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      status: status ?? this.status,
      storePriceRuleId: storePriceRuleId ?? this.storePriceRuleId,
      actorId: actorId,
    );
  }
}
