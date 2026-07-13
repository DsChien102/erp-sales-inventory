import 'package:vet45_partner_domain/domain.dart';

/// Organization contact link row on partner detail.
final class PartnerContactDto {
  const PartnerContactDto({
    required this.personPartnerId,
    required this.displayName,
    this.title,
    this.phone,
    this.phone2,
    this.email,
    this.contactRole,
    required this.isPrimary,
    this.status = PartnerStatus.active,
    this.note,
  });

  final String personPartnerId;
  final String displayName;
  final String? title;
  final String? phone;
  final String? phone2;
  final String? email;
  final String? contactRole;
  final bool isPrimary;
  final PartnerStatus status;
  final String? note;
}
