import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../product_business_status.dart';

final class ProductMustBeActiveRule implements IBusinessRule {
  const ProductMustBeActiveRule(this.status);

  final ProductBusinessStatus status;

  @override
  bool isBroken() => !status.isActive;

  @override
  String get message => 'Product must be active.';
}
