import 'package:vet45_partner_domain/domain.dart';

abstract final class PartnerRpcMapper {
  static String entityTypeToRpc(EntityType entityType) {
    return switch (entityType) {
      EntityType.individual => 'individual',
      EntityType.householdBusiness => 'household_business',
      EntityType.company => 'company',
    };
  }

  static List<String> rolesToRpc(Set<PartnerRole> roles) {
    return roles.map((role) => role.name).toList(growable: false);
  }

  static Map<String, dynamic> registerPartnerParams({
    required BusinessPartner partner,
    required bool confirmDuplicate,
    required String idempotencyKey,
  }) {
    return <String, dynamic>{
      'p_tenant_id': partner.tenantId.value,
      'p_entity_type': entityTypeToRpc(partner.entityType),
      'p_display_name': partner.displayName.value,
      'p_phone': partner.phone.value,
      'p_phone_normalized': partner.phone.normalized,
      'p_roles': rolesToRpc(partner.roles.map((item) => item.id).toSet()),
      'p_individual_name': partner.individualName?.value,
      'p_business_name': partner.businessName?.value,
      'p_company_name': partner.companyName?.value,
      'p_email': partner.email?.value,
      'p_email_normalized': partner.email?.normalized,
      'p_address': partner.address?.value,
      'p_tax_code': partner.taxCode?.value,
      'p_tax_code_normalized': partner.taxCode?.normalized,
      'p_invoice_name': partner.invoiceProfile?.invoiceName?.value,
      'p_invoice_address': partner.invoiceProfile?.invoiceAddress?.value,
      'p_invoice_email': partner.invoiceProfile?.invoiceEmail?.value,
      'p_bank_name': partner.bankAccount?.bankName.value,
      'p_bank_account_number': partner.bankAccount?.accountNumber,
      'p_bank_account_holder': partner.bankAccount?.accountHolder.value,
      'p_note': partner.note,
      'p_confirm_duplicate': confirmDuplicate,
      'p_idempotency_key': idempotencyKey,
    };
  }

  static Map<String, dynamic> updatePartnerParams({
    required BusinessPartner partner,
    required Set<PartnerRole> roles,
    required bool confirmDuplicate,
    required int expectedVersion,
    required String actorId,
  }) {
    return <String, dynamic>{
      'p_tenant_id': partner.tenantId.value,
      'p_partner_id': partner.id.value,
      'p_expected_version': expectedVersion,
      'p_entity_type': entityTypeToRpc(partner.entityType),
      'p_display_name': partner.displayName.value,
      'p_phone': partner.phone.value,
      'p_phone_normalized': partner.phone.normalized,
      'p_roles': rolesToRpc(roles),
      'p_actor_id': actorId,
      'p_individual_name': partner.individualName?.value,
      'p_business_name': partner.businessName?.value,
      'p_company_name': partner.companyName?.value,
      'p_email': partner.email?.value,
      'p_email_normalized': partner.email?.normalized,
      'p_address': partner.address?.value,
      'p_tax_code': partner.taxCode?.value,
      'p_tax_code_normalized': partner.taxCode?.normalized,
      'p_invoice_name': partner.invoiceProfile?.invoiceName?.value,
      'p_invoice_address': partner.invoiceProfile?.invoiceAddress?.value,
      'p_invoice_email': partner.invoiceProfile?.invoiceEmail?.value,
      'p_bank_name': partner.bankAccount?.bankName.value,
      'p_bank_account_number': partner.bankAccount?.accountNumber,
      'p_bank_account_holder': partner.bankAccount?.accountHolder.value,
      'p_note': partner.note,
      'p_confirm_duplicate': confirmDuplicate,
    };
  }

  static Map<String, dynamic> checkDuplicateParams({
    required String tenantId,
    PhoneNumber? phone,
    EmailAddress? email,
    TaxCode? taxCode,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_phone_normalized': phone?.normalized,
      'p_email_normalized': email?.normalized,
      'p_tax_code_normalized': taxCode?.normalized,
    };
  }

  static PartnerDuplicateField duplicateFieldFromRpc(String value) {
    return switch (value) {
      'phone' => PartnerDuplicateField.phone,
      'email' => PartnerDuplicateField.email,
      'tax_code' => PartnerDuplicateField.taxCode,
      _ => throw ArgumentError('Unknown duplicate field: $value'),
    };
  }
}
