import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class CustomFieldNameRequiredRule implements IBusinessRule {
  const CustomFieldNameRequiredRule(this.name);

  final String name;

  @override
  bool isBroken() => name.trim().isEmpty;

  @override
  String get message => 'Tên trường thông tin không được để trống.';
}
