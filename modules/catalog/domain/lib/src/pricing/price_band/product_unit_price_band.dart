import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../exceptions/floor_price_greater_than_list_price_exception.dart';
import '../../ids/product_id.dart';
import '../floor_price.dart';
import '../list_price.dart';
import 'events/product_price_band_changed.dart';
import 'rules/floor_price_not_greater_than_list_price_rule.dart';

/// List + floor price band for a product unit.
final class ProductUnitPriceBand extends Entity<String> implements IAggregateRoot {
  ProductUnitPriceBand({
    required String id,
    required this.tenantId,
    required this.productId,
    this.productUnitId,
    this.listPrice,
    this.floorPrice,
    this.storePriceRuleId,
  }) : super(id: id);

  final String tenantId;
  final String productId;
  final String? productUnitId;
  final ListPrice? listPrice;
  final FloorPrice? floorPrice;
  final String? storePriceRuleId;

  bool get isComplete => listPrice != null && floorPrice != null;

  factory ProductUnitPriceBand.set({
    required String id,
    required TenantId tenantId,
    required ProductId productId,
    String? productUnitId,
    required double listPrice,
    required double floorPrice,
    String? storePriceRuleId,
    String? actorId,
  }) {
    final listPriceVo = ListPrice(amount: listPrice);
    final floorPriceVo = FloorPrice(amount: floorPrice);

    final rule = FloorPriceNotGreaterThanListPriceRule(
      floorPrice: floorPriceVo,
      listPrice: listPriceVo,
    );
    if (rule.isBroken()) {
      throw FloorPriceGreaterThanListPriceException(rule.message);
    }

    final band = ProductUnitPriceBand(
      id: id,
      tenantId: tenantId.value,
      productId: productId.value,
      productUnitId: productUnitId,
      listPrice: listPriceVo,
      floorPrice: floorPriceVo,
      storePriceRuleId: storePriceRuleId,
    );
    band.addDomainEvent(
      ProductPriceBandChanged(
        productId: productId,
        tenantId: tenantId,
        productUnitId: productUnitId,
        listPrice: listPrice,
        floorPrice: floorPrice,
      ),
    );
    return band;
  }

  ProductUnitPriceBand replacePrices({
    required double listPrice,
    required double floorPrice,
    String? storePriceRuleId,
    String? actorId,
  }) {
    return ProductUnitPriceBand.set(
      id: id,
      tenantId: TenantId(tenantId),
      productId: ProductId(productId),
      productUnitId: productUnitId,
      listPrice: listPrice,
      floorPrice: floorPrice,
      storePriceRuleId: storePriceRuleId ?? this.storePriceRuleId,
      actorId: actorId,
    );
  }
}
