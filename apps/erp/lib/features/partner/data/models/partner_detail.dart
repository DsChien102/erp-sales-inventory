import 'partner_enums.dart';
import 'partner_inputs.dart';
import 'person_title.dart';

/// Read-model person profile fields.
final class PersonProfileDto {
  const PersonProfileDto({
    this.title,
    required this.fullName,
    this.nickname,
    required this.phone,
    this.phone2,
    this.email,
    this.taxCode,
    this.invoice,
    this.delivery,
    this.note,
  });

  /// `null` nếu [raw] không phải map.
  static PersonProfileDto? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    return PersonProfileDto(
      title: raw['title'] == null ? null : PersonTitle(raw['title'] as String),
      fullName: raw['full_name'] as String,
      nickname: raw['nickname'] as String?,
      phone: raw['phone'] as String,
      phone2: raw['phone2'] as String?,
      email: raw['email'] as String?,
      taxCode: raw['tax_code'] as String?,
      invoice: _invoiceFromJson(raw['invoice']),
      delivery: _deliveryFromJson(raw['delivery']),
      note: raw['note'] as String?,
    );
  }

  /// Optional honorific — [PersonTitle] wrapping free-form user text.
  final PersonTitle? title;
  final String fullName;
  final String? nickname;
  final String phone;
  final String? phone2;
  final String? email;
  final String? taxCode;
  final InvoiceProfileInput? invoice;
  final DeliveryAddressInput? delivery;
  final String? note;
}

/// Read-model organization profile fields.
final class OrganizationProfileDto {
  const OrganizationProfileDto({
    required this.organizationType,
    required this.organizationName,
    this.shortName,
    this.intlName,
    required this.phone,
    this.email,
    this.taxCode,
    this.companyAddress,
    this.invoice,
    this.delivery,
    this.note,
  });

  /// `null` nếu [raw] không phải map.
  static OrganizationProfileDto? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    return OrganizationProfileDto(
      organizationType: _organizationType(raw['organization_type'] as String),
      organizationName: raw['organization_name'] as String,
      shortName: raw['short_name'] as String?,
      intlName: raw['intl_name'] as String?,
      phone: raw['phone'] as String,
      email: raw['email'] as String?,
      taxCode: raw['tax_code'] as String?,
      companyAddress: raw['company_address'] as String?,
      invoice: _invoiceFromJson(raw['invoice']),
      delivery: _deliveryFromJson(raw['delivery']),
      note: raw['note'] as String?,
    );
  }

  final OrganizationType organizationType;
  final String organizationName;
  final String? shortName;
  final String? intlName;
  final String phone;
  final String? email;
  final String? taxCode;
  final String? companyAddress;
  final InvoiceProfileInput? invoice;
  final DeliveryAddressInput? delivery;
  final String? note;
}

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

  factory PartnerContactDto.fromJson(Map<dynamic, dynamic> c) {
    return PartnerContactDto(
      personPartnerId: c['person_partner_id'] as String,
      displayName: c['display_name'] as String,
      title: c['title'] as String?,
      phone: c['phone'] as String?,
      phone2: c['phone2'] as String?,
      email: c['email'] as String?,
      contactRole: _contactRole(c['contact_role']),
      isPrimary: c['is_primary'] as bool? ?? false,
      status: PartnerStatus.values.byName(c['status'] as String? ?? 'active'),
      note: c['note'] as String?,
    );
  }

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

/// Full partner detail for read screens.
final class PartnerDetailDto {
  const PartnerDetailDto({
    required this.partnerId,
    required this.partnerType,
    required this.status,
    required this.displayName,
    required this.roles,
    required this.availableActions,
    required this.expectedVersion,
    this.personProfile,
    this.organizationProfile,
    this.contacts = const [],
    this.primaryContactOrganizationId,
    this.primaryContactOrganizationName,
    this.createdAt,
    this.updatedAt,
  });

  factory PartnerDetailDto.fromJson(Map<String, dynamic> row) {
    return PartnerDetailDto(
      partnerId: row['partner_id'] as String,
      partnerType: PartnerType.values.byName(row['partner_type'] as String),
      status: PartnerStatus.values.byName(row['status'] as String),
      displayName: row['display_name'] as String,
      roles: (row['roles'] as List)
          .map((r) => PartnerRoleType.values.byName(r as String))
          .toList(growable: false),
      availableActions: (row['available_actions'] as List? ?? const [])
          .map((a) => PartnerAvailableAction.values.byName(a as String))
          .toList(growable: false),
      expectedVersion: row['expected_version'] as int,
      personProfile: PersonProfileDto.fromJson(row['person_profile']),
      organizationProfile: OrganizationProfileDto.fromJson(row['organization_profile']),
      contacts: (row['contacts'] as List? ?? const [])
          .map((c) => PartnerContactDto.fromJson(c as Map))
          .toList(growable: false),
      primaryContactOrganizationId: row['primary_contact_organization_id'] as String?,
      primaryContactOrganizationName: row['primary_contact_organization_name'] as String?,
      createdAt: row['created_at'] == null ? null : DateTime.parse(row['created_at'] as String),
      updatedAt: row['updated_at'] == null ? null : DateTime.parse(row['updated_at'] as String),
    );
  }

  final String partnerId;
  final PartnerType partnerType;
  final PartnerStatus status;
  final String displayName;
  final List<PartnerRoleType> roles;
  final List<PartnerAvailableAction> availableActions;
  final int expectedVersion;
  final PersonProfileDto? personProfile;
  final OrganizationProfileDto? organizationProfile;
  final List<PartnerContactDto> contacts;
  final String? primaryContactOrganizationId;
  final String? primaryContactOrganizationName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

OrganizationType _organizationType(String raw) {
  return switch (raw) {
    'company' => OrganizationType.company,
    'business_household' || 'businessHousehold' => OrganizationType.businessHousehold,
    'other' => OrganizationType.other,
    _ => OrganizationType.values.byName(raw),
  };
}

String? _contactRole(Object? raw) {
  final value = raw is String ? raw.trim() : '';
  return value.isEmpty || value == 'primary' ? null : value;
}

InvoiceProfileInput? _invoiceFromJson(Object? raw) {
  final map = _asStringKeyedMap(raw);
  if (map == null) return null;
  final name = _nullableString(map['name'] ?? map['invoice_name']);
  final address = _nullableString(map['address'] ?? map['invoice_address']);
  final email = _nullableString(map['email'] ?? map['invoice_email']);
  if (name == null && address == null && email == null) return null;
  return InvoiceProfileInput(
    invoiceName: name,
    invoiceAddress: address,
    invoiceEmail: email,
  );
}

DeliveryAddressInput? _deliveryFromJson(Object? raw) {
  final map = _asStringKeyedMap(raw);
  if (map == null) return null;
  final province = _nullableString(map['province']);
  final commune = _nullableString(map['commune']);
  final address = _nullableString(map['address']);
  if (province == null && commune == null && address == null) return null;
  return DeliveryAddressInput(
    province: province,
    commune: commune,
    address: address,
  );
}

Map<String, dynamic>? _asStringKeyedMap(Object? raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

String? _nullableString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
