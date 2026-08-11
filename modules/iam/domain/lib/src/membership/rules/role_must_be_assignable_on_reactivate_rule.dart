import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class RoleMustBeAssignableOnReactivateRule implements IBusinessRule {
  const RoleMustBeAssignableOnReactivateRule({required this.roleAssignable});

  final bool roleAssignable;

  @override
  bool isBroken() => !roleAssignable;

  @override
  String get message => 'ROLE_NOT_ASSIGNABLE';
}
