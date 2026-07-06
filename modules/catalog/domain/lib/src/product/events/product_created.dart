import '../../ids/product_id.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class ProductCreated extends DomainEventBase {
  ProductCreated({
    required this.productId,
    required this.tenantId,
    required this.productName,
  });

  final ProductId productId;
  final TenantId tenantId;
  final String productName;
}
