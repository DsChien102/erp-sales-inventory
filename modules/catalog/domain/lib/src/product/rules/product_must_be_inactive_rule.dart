import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../shared/product_status.dart';

final class ProductMustBeInactiveRule implements IBusinessRule {
  const ProductMustBeInactiveRule(this.status);

  final ProductStatus status;

  @override
  bool isBroken() => status != ProductStatus.inactive;

  @override
  String get message => 'Product must be inactive.';
}
