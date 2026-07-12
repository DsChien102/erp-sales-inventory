import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../ids/product_id.dart';
import '../product_reference_id.dart';

final class ProductCreated extends DomainEventBase {
  ProductCreated({
    required this.productId,
    required this.tenantId,
    required this.referenceId,
    required this.productName,
  });

  final ProductId productId;
  final TenantId tenantId;
  final ProductReferenceId referenceId;
  final String productName;
}
