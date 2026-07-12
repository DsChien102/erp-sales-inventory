import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../shared/product_status.dart';

final class ProductMustBeActiveRule implements IBusinessRule {
  const ProductMustBeActiveRule(this.status);

  final ProductStatus status;

  @override
  bool isBroken() => status != ProductStatus.active;

  @override
  String get message => 'Product must be active.';
}
