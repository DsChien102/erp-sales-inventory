import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/partner_role_type.dart';

class PartnerMustHaveAtLeastOneRoleRule implements IBusinessRule {
  const PartnerMustHaveAtLeastOneRoleRule(this.roles);

  final List<PartnerRoleType> roles;

  @override
  bool isBroken() => roles.isEmpty;

  @override
  String get message => 'Partner must have at least one role';
}
