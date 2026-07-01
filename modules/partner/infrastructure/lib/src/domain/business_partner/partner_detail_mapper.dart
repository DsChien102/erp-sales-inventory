import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

abstract final class PartnerDetailMapper {
  static PartnerDetailDto fromRow(Map<String, dynamic> row) {
    final roles = <PartnerRole>{};
    if (row['has_customer_role'] == true) {
      roles.add(PartnerRole.customer);
    }
    if (row['has_supplier_role'] == true) {
      roles.add(PartnerRole.supplier);
    }

    return PartnerDetailDto(
      id: row['id'] as String,
      displayName: row['display_name'] as String,
      phone: row['phone'] as String,
      email: row['email'] as String?,
      address: row['address'] as String?,
      taxCode: row['tax_code'] as String?,
      invoiceName: row['invoice_name'] as String?,
      invoiceAddress: row['invoice_address'] as String?,
      invoiceEmail: row['invoice_email'] as String?,
      bankName: row['bank_name'] as String?,
      bankAccountNumber: row['bank_account_number'] as String?,
      bankAccountHolder: row['bank_account_holder'] as String?,
      note: row['note'] as String?,
      individualName: row['individual_name'] as String?,
      businessName: row['business_name'] as String?,
      companyName: row['company_name'] as String?,
      roles: roles,
      entityType: _entityTypeFromRpc(row['entity_type'] as String),
      status: _statusFromRpc(row['status'] as String),
      createdBy: row['created_by'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedBy: row['updated_by'] as String,
      updatedAt: DateTime.parse(row['updated_at'] as String),
      version: (row['version'] as num).toInt(),
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
