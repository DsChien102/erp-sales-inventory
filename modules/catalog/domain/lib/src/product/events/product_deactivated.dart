import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../ids/product_id.dart';

final class ProductDeactivated extends DomainEventBase {
  ProductDeactivated({
    required this.productId,
    required this.tenantId,
  });

  final ProductId productId;
  final TenantId tenantId;
}
