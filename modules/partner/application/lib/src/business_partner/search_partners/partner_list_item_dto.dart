import 'package:vet45_partner_domain/domain.dart';

final class PartnerListItemDto {
  const PartnerListItemDto({
    required this.id,
    required this.displayName,
    required this.phone,
    required this.roles,
    required this.entityType,
    required this.status,
    required this.updatedAt,
    this.email,
    this.taxCode,
  });

  final String id;
  final String displayName;
  final String phone;
  final String? email;
  final String? taxCode;
  final Set<PartnerRole> roles;
  final EntityType entityType;
  final PartnerStatus status;
  final DateTime updatedAt;
}
