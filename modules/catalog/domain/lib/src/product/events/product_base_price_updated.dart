import '../../ids/product_id.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class ProductBasePriceUpdated extends DomainEventBase {
  ProductBasePriceUpdated({
    required this.productId,
    required this.tenantId,
    required this.basePrice,
  });

  final ProductId productId;
  final TenantId tenantId;
  final double basePrice;
}
