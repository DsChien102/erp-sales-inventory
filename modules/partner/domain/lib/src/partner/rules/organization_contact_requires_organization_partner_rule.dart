import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/partner_type.dart';

class OrganizationContactRequiresOrganizationPartnerRule
    implements IBusinessRule {
  const OrganizationContactRequiresOrganizationPartnerRule(this.partnerType);

  final PartnerType partnerType;

  @override
  bool isBroken() => partnerType != PartnerType.organization;

  @override
  String get message => 'Contacts can only be managed on organization partners';
}
