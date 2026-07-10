import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../partner_id.dart';

/// Link between an organization partner and a person partner contact.
final class OrganizationContact extends ValueObject {
  const OrganizationContact({
    required this.personPartnerId,
    this.contactRole,
    this.isPrimary = false,
    this.note,
  });

  final PartnerId personPartnerId;
  final String? contactRole;
  final bool isPrimary;
  final String? note;

  OrganizationContact copyWith({
    String? contactRole,
    bool? isPrimary,
    String? note,
  }) {
    return OrganizationContact(
      personPartnerId: personPartnerId,
      contactRole: contactRole ?? this.contactRole,
      isPrimary: isPrimary ?? this.isPrimary,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [personPartnerId, contactRole, isPrimary, note];
}
