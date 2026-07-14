import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/partner_type.dart';
import '../entities/organization_profile.dart';
import '../entities/person_profile.dart';

class PersonOrOrganizationProfileExclusiveRule implements IBusinessRule {
  const PersonOrOrganizationProfileExclusiveRule({
    required this.partnerType,
    this.personProfile,
    this.organizationProfile,
  });

  final PartnerType partnerType;
  final PersonProfile? personProfile;
  final OrganizationProfile? organizationProfile;

  @override
  bool isBroken() {
    final hasPerson = personProfile != null;
    final hasOrg = organizationProfile != null;
    if (hasPerson && hasOrg) {
      return true;
    }
    return switch (partnerType) {
      PartnerType.person => !hasPerson || hasOrg,
      PartnerType.organization => !hasOrg || hasPerson,
    };
  }

  @override
  String get message =>
      'Partner type must match exactly one profile (person or organization)';
}
