import 'package:vet45_partner_domain/domain.dart';

/// Partner list row for search results.
final class PartnerListItemDto {
  const PartnerListItemDto({
    required this.partnerId,
    required this.displayName,
    required this.partnerType,
    required this.status,
    required this.roles,
    this.phone,
    this.email,
    this.taxCode,
    this.updatedAt,
  });

  final String partnerId;
  final String displayName;
  final PartnerType partnerType;
  final PartnerStatus status;
  final List<PartnerRoleType> roles;
  final String? phone;
  final String? email;
  final String? taxCode;
  final DateTime? updatedAt;
}
