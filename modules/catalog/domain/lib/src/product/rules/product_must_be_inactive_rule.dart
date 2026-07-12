import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../product_business_status.dart';

final class ProductMustBeInactiveRule implements IBusinessRule {
  const ProductMustBeInactiveRule(this.status);

  final ProductBusinessStatus status;

  @override
  bool isBroken() => !status.isInactive;

  @override
  String get message => 'Product must be inactive.';
}
