import 'partner_enums.dart';

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

  factory PartnerDuplicateMatchDto.fromJson(Map<String, dynamic> row) {
    final field = _matchField(row['matched_field'] as String);
    return PartnerDuplicateMatchDto(
      partnerId: row['partner_id'] as String,
      displayName: row['display_name'] as String,
      matchedField: field,
      matchLevel: _deriveMatchLevel(field),
      partnerType: PartnerType.values.byName(row['partner_type'] as String),
      matchedValue: row['matched_value'] as String?,
    );
  }

  final String partnerId;
  final String displayName;
  final PartnerDuplicateMatchField matchedField;
  final PartnerDuplicateMatchLevel matchLevel;
  final PartnerType partnerType;
  final String? matchedValue;

  /// RPC trả snake_case (`tax_code`); enum Dart là camelCase (`taxCode`).
  static PartnerDuplicateMatchField _matchField(String raw) {
    return switch (raw) {
      'tax_code' || 'taxCode' => PartnerDuplicateMatchField.taxCode,
      'phone' => PartnerDuplicateMatchField.phone,
      'email' => PartnerDuplicateMatchField.email,
      'name' => PartnerDuplicateMatchField.name,
      _ => PartnerDuplicateMatchField.values.byName(raw),
    };
  }

  static PartnerDuplicateMatchLevel _deriveMatchLevel(
    PartnerDuplicateMatchField field,
  ) {
    return switch (field) {
      PartnerDuplicateMatchField.phone ||
      PartnerDuplicateMatchField.email ||
      PartnerDuplicateMatchField.taxCode => PartnerDuplicateMatchLevel.exact,
      PartnerDuplicateMatchField.name => PartnerDuplicateMatchLevel.possible,
    };
  }
}
