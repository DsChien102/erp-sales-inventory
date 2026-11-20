import 'partner_enums.dart';

/// Partner list row for search results.
final class PartnerListItemDto {
  const PartnerListItemDto({
    required this.partnerId,
    required this.displayName,
    required this.partnerType,
    required this.status,
    required this.roles,
    this.phone,
    this.email,
    this.taxCode,
    this.updatedAt,
  });

  factory PartnerListItemDto.fromJson(Map<String, dynamic> item) {
    return PartnerListItemDto(
      partnerId: item['partner_id'] as String,
      partnerType: PartnerType.values.byName(item['partner_type'] as String),
      status: PartnerStatus.values.byName(item['status'] as String),
      displayName: item['display_name'] as String,
      phone: item['phone'] as String?,
      email: item['email'] as String?,
      taxCode: item['tax_code'] as String?,
      updatedAt: item['updated_at'] == null
          ? null
          : DateTime.tryParse(item['updated_at'] as String),
      roles: (item['roles'] as List)
          .map((r) => PartnerRoleType.values.byName(r as String))
          .toList(growable: false),
    );
  }

  final String partnerId;
  final String displayName;
  final PartnerType partnerType;
  final PartnerStatus status;
  final List<PartnerRoleType> roles;
  final String? phone;
  final String? email;
  final String? taxCode;
  final DateTime? updatedAt;
}

/// Paginated partner search result.
final class PartnerSearchResultDto {
  const PartnerSearchResultDto({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  /// `row` rỗng `{}` → items rỗng, total 0, page 1, limit 0.
  factory PartnerSearchResultDto.fromJson(Map<String, dynamic> row) {
    final items = (row['items'] as List? ?? const [])
        .map((item) => PartnerListItemDto.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
    return PartnerSearchResultDto(
      items: items,
      total: row['total'] as int? ?? items.length,
      page: row['page'] as int? ?? 1,
      limit: row['limit'] as int? ?? items.length,
    );
  }

  final List<PartnerListItemDto> items;
  final int page;
  final int limit;
  final int total;
}
