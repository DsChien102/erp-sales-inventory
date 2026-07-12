import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class CustomFieldGroupNameRequiredRule implements IBusinessRule {
  const CustomFieldGroupNameRequiredRule(this.name);

  final String name;

  @override
  bool isBroken() => name.trim().isEmpty;

  @override
  String get message => 'Tên nhóm thông tin không được để trống.';
}
