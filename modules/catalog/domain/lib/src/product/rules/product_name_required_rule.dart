import '../../value_objects/product_name.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class ProductNameRequiredRule implements IBusinessRule {
  ProductNameRequiredRule(ProductName? name) : _name = name;

  final ProductName? _name;

  @override
  bool isBroken() => _name == null;

  @override
  String get message => 'Product name is required.';
}
