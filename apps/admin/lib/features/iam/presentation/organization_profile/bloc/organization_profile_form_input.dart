/// Editable tenant contact/profile fields (S12 allowlist).
final class TenantProfileFormInput {
  const TenantProfileFormInput({
    required this.displayName,
    this.contactEmail,
    this.contactPhone,
    this.contactAddressText,
    this.provinceCode,
    this.communeCode,
  });

  final String displayName;
  final String? contactEmail;
  final String? contactPhone;
  final String? contactAddressText;
  final String? provinceCode;
  final String? communeCode;
}

/// Editable legal profile fields (S12 allowlist).
final class LegalProfileFormInput {
  const LegalProfileFormInput({
    required this.legalEntityType,
    required this.legalName,
    required this.taxCode,
    this.registeredAddressText,
    this.provinceCode,
    this.communeCode,
  });

  final String legalEntityType;
  final String legalName;
  final String taxCode;
  final String? registeredAddressText;
  final String? provinceCode;
  final String? communeCode;
}
