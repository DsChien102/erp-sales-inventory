import '../../ids/product_id.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class ProductPriceBandChanged extends DomainEventBase {
  ProductPriceBandChanged({
    required this.productId,
    required this.tenantId,
    required this.productUnitId,
    required this.listPrice,
    required this.floorPrice,
  });

  final ProductId productId;
  final TenantId tenantId;
  final String productUnitId;
  final double listPrice;
  final double floorPrice;
}
