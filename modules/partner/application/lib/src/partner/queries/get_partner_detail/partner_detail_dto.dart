import 'package:vet45_partner_domain/domain.dart';

import 'organization_profile_dto.dart';
import 'partner_available_action.dart';
import 'partner_contact_dto.dart';
import 'person_profile_dto.dart';

/// Full partner detail for read screens.
final class PartnerDetailDto {
  const PartnerDetailDto({
    required this.partnerId,
    required this.partnerType,
    required this.status,
    required this.displayName,
    required this.roles,
    required this.availableActions,
    required this.expectedVersion,
    this.personProfile,
    this.organizationProfile,
    this.contacts = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String partnerId;
  final PartnerType partnerType;
  final PartnerStatus status;
  final String displayName;
  final List<PartnerRoleType> roles;
  final List<PartnerAvailableAction> availableActions;
  final int expectedVersion;
  final PersonProfileDto? personProfile;
  final OrganizationProfileDto? organizationProfile;
  final List<PartnerContactDto> contacts;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
