/// Hồ sơ tổ chức đọc từ `get_tenant` / `update_tenant_profile`.
final class TenantProfile {
  const TenantProfile({
    required this.tenantId,
    required this.displayName,
    required this.version,
    required this.businessTimezone,
    required this.baseCurrencyCode,
    required this.createdAt,
    required this.updatedAt,
    this.contactEmail,
    this.contactPhone,
    this.contactAddressText,
    this.provinceCode,
    this.communeCode,
    this.activatedAt,
    this.legalProfile,
  });

  final String tenantId;
  final String displayName;
  final int version;
  final String businessTimezone;
  final String baseCurrencyCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? contactEmail;
  final String? contactPhone;
  final String? contactAddressText;
  final String? provinceCode;
  final String? communeCode;
  final DateTime? activatedAt;
  final TenantLegalProfile? legalProfile;

  factory TenantProfile.fromJson(Map<String, dynamic> row) {
    final legalRaw = row['legal_profile'];
    TenantLegalProfile? legalProfile;
    if (legalRaw is Map && legalRaw.isNotEmpty) {
      legalProfile = TenantLegalProfile.fromJson(Map<String, dynamic>.from(legalRaw));
    }

    return TenantProfile(
      tenantId: row['tenant_id'] as String,
      displayName: row['display_name'] as String? ?? row['name'] as String? ?? '',
      version: (row['version'] as num?)?.toInt() ?? 1,
      businessTimezone: row['business_timezone'] as String? ?? 'Asia/Ho_Chi_Minh',
      baseCurrencyCode: row['base_currency_code'] as String? ?? 'VND',
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      contactEmail: row['contact_email'] as String?,
      contactPhone: row['contact_phone'] as String?,
      contactAddressText: row['contact_address_text'] as String?,
      provinceCode: row['province_code'] as String?,
      communeCode: row['commune_code'] as String?,
      activatedAt: row['activated_at'] == null
          ? null
          : DateTime.parse(row['activated_at'] as String),
      legalProfile: legalProfile,
    );
  }

  TenantProfile copyWith({int? version}) {
    return TenantProfile(
      tenantId: tenantId,
      displayName: displayName,
      version: version ?? this.version,
      businessTimezone: businessTimezone,
      baseCurrencyCode: baseCurrencyCode,
      createdAt: createdAt,
      updatedAt: updatedAt,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      contactAddressText: contactAddressText,
      provinceCode: provinceCode,
      communeCode: communeCode,
      activatedAt: activatedAt,
      legalProfile: legalProfile,
    );
  }
}

/// Loại hình pháp lý của tổ chức (hồ sơ pháp lý).
enum LegalEntityType { householdBusiness, enterprise }

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

final class TenantLegalProfile {
  const TenantLegalProfile({
    required this.tenantId,
    required this.legalEntityType,
    required this.legalName,
    required this.taxCode,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.registeredAddressText,
    this.provinceCode,
    this.communeCode,
  });

  final String tenantId;
  final LegalEntityType legalEntityType;
  final String legalName;
  final String taxCode;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? registeredAddressText;
  final String? provinceCode;
  final String? communeCode;

  factory TenantLegalProfile.fromJson(Map<String, dynamic> row) {
    return TenantLegalProfile(
      tenantId: row['tenant_id'] as String,
      legalEntityType:
          LegalEntityTypeCodes.fromCode(row['legal_entity_type'] as String?) ??
          LegalEntityType.enterprise,
      legalName: row['legal_name'] as String,
      taxCode: row['tax_code'] as String,
      version: (row['version'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      registeredAddressText: row['registered_address_text'] as String?,
      provinceCode: row['province_code'] as String?,
      communeCode: row['commune_code'] as String?,
    );
  }
}

