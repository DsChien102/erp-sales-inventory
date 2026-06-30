import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

abstract final class PartnerListMapper {
  static PartnerListItemDto fromRow(Map<String, dynamic> row) {
    final roles = <PartnerRole>{};
    if (row['has_customer_role'] == true) {
      roles.add(PartnerRole.customer);
    }
    if (row['has_supplier_role'] == true) {
      roles.add(PartnerRole.supplier);
    }

    return PartnerListItemDto(
      id: row['id'] as String,
      displayName: row['display_name'] as String,
      phone: row['phone'] as String,
      email: row['email'] as String?,
      taxCode: row['tax_code'] as String?,
      roles: roles,
      entityType: _entityTypeFromRpc(row['entity_type'] as String),
      status: _statusFromRpc(row['status'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  static EntityType _entityTypeFromRpc(String value) {
    return switch (value) {
      'individual' => EntityType.individual,
      'household_business' => EntityType.householdBusiness,
      'company' => EntityType.company,
      _ => throw ArgumentError('Unknown entity type: $value'),
    };
  }

  static PartnerStatus _statusFromRpc(String value) {
    return switch (value) {
      'active' => PartnerStatus.active,
      'inactive' => PartnerStatus.inactive,
      _ => throw ArgumentError('Unknown partner status: $value'),
    };
  }
}
