import 'package:vet45_partner_domain/domain.dart';

import 'partner_duplicate_match_field.dart';
import 'partner_duplicate_match_level.dart';

/// Duplicate partner match returned by dup-check query.
final class PartnerDuplicateMatchDto {
  const PartnerDuplicateMatchDto({
    required this.partnerId,
    required this.displayName,
    required this.matchedField,
    required this.matchLevel,
    required this.partnerType,
    this.matchedValue,
  });

  final String partnerId;
  final String displayName;
  final PartnerDuplicateMatchField matchedField;
  final PartnerDuplicateMatchLevel matchLevel;
  final PartnerType partnerType;
  final String? matchedValue;
}
