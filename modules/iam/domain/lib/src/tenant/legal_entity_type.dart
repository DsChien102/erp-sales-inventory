/// Legal entity type for Tenant Legal Profile (Phase 1).
enum LegalEntityType {
  householdBusiness,
  enterprise,
}

extension LegalEntityTypeCodes on LegalEntityType {
  String get code => switch (this) {
    LegalEntityType.householdBusiness => 'HOUSEHOLD_BUSINESS',
    LegalEntityType.enterprise => 'ENTERPRISE',
  };

  static LegalEntityType? fromCode(String? raw) => switch (raw) {
    'HOUSEHOLD_BUSINESS' => LegalEntityType.householdBusiness,
    'ENTERPRISE' => LegalEntityType.enterprise,
    _ => null,
  };
}
