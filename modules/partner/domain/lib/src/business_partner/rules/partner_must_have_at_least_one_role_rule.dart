import '../../shared/partner_role.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class PartnerMustHaveAtLeastOneRoleRule implements IBusinessRule {
  PartnerMustHaveAtLeastOneRoleRule(Set<PartnerRole> roles) : _roles = roles;

  final Set<PartnerRole> _roles;

  @override
  bool isBroken() => _roles.isEmpty;

  @override
  String get message => 'Partner must have at least one role.';
}
