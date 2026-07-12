import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../ids/product_id.dart';

final class ProductStockAdjusted extends DomainEventBase {
  ProductStockAdjusted({
    required this.productId,
    required this.tenantId,
    required this.quantity,
  });

  final ProductId productId;
  final TenantId tenantId;
  final int quantity;
}
