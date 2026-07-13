import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../../ids/product_id.dart';
import '../product_price_band_status.dart';

final class ProductPriceBandChanged extends DomainEventBase {
  ProductPriceBandChanged({
    required this.productId,
    required this.tenantId,
    this.productUnitId,
    required this.listBeforeVat,
    required this.listAfterVat,
    this.floorBeforeVat,
    this.floorAfterVat,
    required this.effectiveFrom,
    this.effectiveTo,
    required this.status,
  });

  final ProductId productId;
  final TenantId tenantId;
  final String? productUnitId;
  final int listBeforeVat;
  final int? floorBeforeVat;
  final int listAfterVat;
  final int? floorAfterVat;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final ProductPriceBandStatus status;
}
