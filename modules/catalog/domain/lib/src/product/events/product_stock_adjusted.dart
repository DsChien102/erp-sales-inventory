import '../../ids/product_id.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class ProductStockAdjusted extends DomainEventBase {
  ProductStockAdjusted({
    required this.productId,
    required this.tenantId,
    required this.quantity,
  });

  final ProductId productId;
  final TenantId tenantId;
  final double quantity;
}
