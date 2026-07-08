import '../product_base_unit.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class BaseUnitRequiredForStockRule implements IBusinessRule {
  BaseUnitRequiredForStockRule(ProductBaseUnit? baseUnit) : _baseUnit = baseUnit;

  final ProductBaseUnit? _baseUnit;

  @override
  bool isBroken() => _baseUnit == null;

  @override
  String get message => 'Sản phẩm bắt buộc phải có Đơn vị cơ sở trước khi nhập tồn kho (BR-03).';
}
