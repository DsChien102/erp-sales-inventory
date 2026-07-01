import 'package:vet45_partner_domain/domain.dart';

final class PartnerDuplicateMatchDto {
  const PartnerDuplicateMatchDto({
    required this.field,
    required this.businessPartnerId,
    required this.displayName,
    required this.matchedValue,
  });

  final PartnerDuplicateField field;
  final String businessPartnerId;
  final String displayName;
  final String matchedValue;

  factory PartnerDuplicateMatchDto.fromDomain(PartnerDuplicateMatch match) {
    return PartnerDuplicateMatchDto(
      field: match.field,
      businessPartnerId: match.businessPartnerId.value,
      displayName: match.displayName,
      matchedValue: match.matchedValue,
    );
  }
}
