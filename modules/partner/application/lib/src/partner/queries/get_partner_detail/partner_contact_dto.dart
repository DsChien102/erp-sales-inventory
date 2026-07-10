/// Organization contact link row on partner detail.
final class PartnerContactDto {
  const PartnerContactDto({
    required this.personPartnerId,
    required this.displayName,
    this.phone,
    this.email,
    this.contactRole,
    required this.isPrimary,
    this.note,
  });

  final String personPartnerId;
  final String displayName;
  final String? phone;
  final String? email;
  final String? contactRole;
  final bool isPrimary;
  final String? note;
}
