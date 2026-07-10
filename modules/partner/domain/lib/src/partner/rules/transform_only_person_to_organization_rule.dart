import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/partner_type.dart';

class TransformOnlyPersonToOrganizationRule implements IBusinessRule {
  const TransformOnlyPersonToOrganizationRule(this.partnerType);

  final PartnerType partnerType;

  @override
  bool isBroken() => partnerType != PartnerType.person;

  @override
  String get message => 'Only person partners can transform to organization';
}
