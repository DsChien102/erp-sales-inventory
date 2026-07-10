import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

/// RPC param/result mapping for partner read operations.
abstract final class PartnerReadRpcMapper {
  static Map<String, dynamic> searchParams(SearchPartnersQuery query) {
    return <String, dynamic>{
      'p_tenant_id': query.tenantId,
      'p_query': query.query,
      'p_partner_type': query.partnerType?.name,
      'p_role': query.role?.name,
      'p_status': query.status?.name,
      'p_page': query.page,
      'p_limit': query.limit,
      'p_sort': query.sort,
    };
  }

  static Map<String, dynamic> detailParams(GetPartnerDetailQuery query) {
    return <String, dynamic>{
      'p_tenant_id': query.tenantId,
      'p_partner_id': query.partnerId,
    };
  }

  static Map<String, dynamic> duplicateParams(
    CheckDuplicatePartnersQuery query,
  ) {
    return <String, dynamic>{
      'p_tenant_id': query.tenantId,
      'p_phone': query.phone,
      'p_email': query.email,
      'p_tax_code': query.taxCode,
      'p_name': query.name,
      'p_exclude_partner_id': query.excludePartnerId,
    };
  }

  static Map<String, dynamic> deleteEligibilityParams(
    CheckDeleteEligibilityQuery query,
  ) {
    return <String, dynamic>{
      'p_tenant_id': query.tenantId,
      'p_partner_id': query.partnerId,
    };
  }

  static Map<String, dynamic> historyParams(GetPartnerHistoryQuery query) {
    return <String, dynamic>{
      'p_tenant_id': query.tenantId,
      'p_partner_id': query.partnerId,
      'p_role': query.role?.name,
      'p_transaction_type': query.transactionType?.name,
      'p_date_from': query.dateFrom?.toIso8601String(),
      'p_date_to': query.dateTo?.toIso8601String(),
      'p_page': query.page,
    };
  }

  static Map<String, dynamic> recordHistoryParams(
    RecordPartnerHistoryCommand command,
  ) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_partner_id': command.partnerId,
      'p_role': command.role.name,
      'p_transaction_type': command.transactionType.name,
      'p_source_module': command.sourceModule,
      'p_source_id': command.sourceId,
      'p_reference_code': command.referenceCode,
      'p_transaction_date': command.transactionDate.toIso8601String(),
      'p_status': command.status,
      'p_amount': command.amount,
      'p_currency': command.currency,
      'p_can_open_source': command.canOpenSource,
    };
  }

  static PartnerSearchResultDto mapSearchResult(Map<String, dynamic> row) {
    final items = (row['items'] as List? ?? const [])
        .map(
          (item) => PartnerListItemDto(
            partnerId: (item as Map)['partner_id'] as String,
            partnerType: PartnerType.values.byName(item['partner_type'] as String),
            status: PartnerStatus.values.byName(item['status'] as String),
            displayName: item['display_name'] as String,
            phone: item['phone'] as String?,
            roles: (item['roles'] as List)
                .map((r) => PartnerRoleType.values.byName(r as String))
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
    return PartnerSearchResultDto(
      items: items,
      total: row['total'] as int? ?? items.length,
      page: row['page'] as int? ?? 1,
      limit: row['limit'] as int? ?? items.length,
    );
  }

  static PartnerDetailDto mapDetailResult(Map<String, dynamic> row) {
    return PartnerDetailDto(
      partnerId: row['partner_id'] as String,
      partnerType: PartnerType.values.byName(row['partner_type'] as String),
      status: PartnerStatus.values.byName(row['status'] as String),
      displayName: row['display_name'] as String,
      roles: (row['roles'] as List)
          .map((r) => PartnerRoleType.values.byName(r as String))
          .toList(growable: false),
      availableActions: (row['available_actions'] as List? ?? const [])
          .map(
            (a) => PartnerAvailableAction.values.byName(a as String),
          )
          .toList(growable: false),
      expectedVersion: row['expected_version'] as int,
      personProfile: _personDto(row['person_profile']),
      organizationProfile: _organizationDto(row['organization_profile']),
      contacts: (row['contacts'] as List? ?? const [])
          .map(
            (c) => PartnerContactDto(
              personPartnerId: (c as Map)['person_partner_id'] as String,
              displayName: c['display_name'] as String,
              phone: c['phone'] as String?,
              contactRole: c['contact_role'] as String?,
              isPrimary: c['is_primary'] as bool? ?? false,
            ),
          )
          .toList(growable: false),
      createdAt: row['created_at'] == null
          ? null
          : DateTime.parse(row['created_at'] as String),
      updatedAt: row['updated_at'] == null
          ? null
          : DateTime.parse(row['updated_at'] as String),
    );
  }

  static DeleteEligibilityDto mapDeleteEligibility(Map<String, dynamic> row) {
    return DeleteEligibilityDto(
      eligible: row['eligible'] as bool,
      reason: row['reason'] as String?,
    );
  }

  static PartnerHistoryResultDto mapHistoryResult(Map<String, dynamic> row) {
    final items = (row['items'] as List? ?? const [])
        .map(
          (item) => PartnerHistoryItemDto(
            historyId: (item as Map)['history_id'] as String,
            role: PartnerRoleType.values.byName(item['role'] as String),
            transactionType: PartnerTransactionType.values.byName(
              item['transaction_type'] as String,
            ),
            sourceModule: item['source_module'] as String,
            sourceId: item['source_id'] as String,
            referenceCode: item['reference_code'] as String,
            transactionDate: DateTime.parse(item['transaction_date'] as String),
            status: item['status'] as String,
            amount: (item['amount'] as num?)?.toDouble(),
            currency: item['currency'] as String?,
            canOpenSource: item['can_open_source'] as bool? ?? false,
          ),
        )
        .toList(growable: false);
    return PartnerHistoryResultDto(
      items: items,
      total: row['total'] as int? ?? items.length,
      page: row['page'] as int? ?? 1,
      limit: row['limit'] as int? ?? items.length,
    );
  }

  static List<PartnerDuplicateMatchDto> mapDuplicateMatches(
    List<Map<String, dynamic>> rows,
  ) {
    return rows
        .map(
          (row) => PartnerDuplicateMatchDto(
            partnerId: row['partner_id'] as String,
            displayName: row['display_name'] as String,
            matchedField: PartnerDuplicateMatchField.values.byName(
              row['matched_field'] as String,
            ),
            matchLevel: _deriveMatchLevel(
              PartnerDuplicateMatchField.values.byName(
                row['matched_field'] as String,
              ),
            ),
            partnerType: PartnerType.values.byName(
              row['partner_type'] as String,
            ),
            matchedValue: row['matched_value'] as String?,
          ),
        )
        .toList(growable: false);
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

  static PersonProfileDto? _personDto(Object? raw) {
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
      invoice: _invoiceDto(raw['invoice']),
      delivery: _deliveryDto(raw['delivery']),
      note: raw['note'] as String?,
    );
  }

  static OrganizationProfileDto? _organizationDto(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    return OrganizationProfileDto(
      organizationType: OrganizationType.values.byName(
        raw['organization_type'] as String,
      ),
      organizationName: raw['organization_name'] as String,
      shortName: raw['short_name'] as String?,
      intlName: raw['intl_name'] as String?,
      phone: raw['phone'] as String,
      email: raw['email'] as String?,
      taxCode: raw['tax_code'] as String?,
      companyAddress: raw['company_address'] as String?,
      invoice: _invoiceDto(raw['invoice']),
      delivery: _deliveryDto(raw['delivery']),
      note: raw['note'] as String?,
    );
  }

  static InvoiceProfileInput? _invoiceDto(Object? raw) {
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

  static DeliveryAddressInput? _deliveryDto(Object? raw) {
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

  static Map<String, dynamic>? _asStringKeyedMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
