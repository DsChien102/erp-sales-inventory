import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class BaseUnitRequiredForStockRule implements IBusinessRule {
  const BaseUnitRequiredForStockRule({required this.hasBaseUnit});

  final bool hasBaseUnit;

  @override
  bool isBroken() => !hasBaseUnit;

  @override
  String get message => 'Sản phẩm bắt buộc phải có Đơn vị cơ sở trước khi nhập tồn kho (BR-03).';
}
