import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

/// RPC param/result mapping for partner write operations.
abstract final class PartnerRpcMapper {
  static Map<String, dynamic> createPartnerParams(CreatePartnerCommand command) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_partner_type': command.partnerType.name,
      'p_roles': command.roles.map((r) => r.name).toList(),
      'p_person_profile': _personInput(command.personProfile),
      'p_organization_profile': _organizationInput(command.organizationProfile),
      'p_organization_primary_contact': _personInput(
        command.organizationPrimaryContact,
      ),
      'p_confirm_duplicate': command.confirmDuplicate,
    };
  }

  static Map<String, dynamic> updatePartnerParams(
    UpdatePartnerProfileCommand command,
  ) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_partner_id': command.partnerId,
      'p_roles': command.roles.map((r) => r.name).toList(),
      'p_person_profile': _personInput(command.personProfile),
      'p_organization_profile': _organizationInput(command.organizationProfile),
      'p_confirm_duplicate': command.confirmDuplicate,
      'p_expected_version': command.expectedVersion,
    };
  }

  static Map<String, dynamic> transformPartnerParams(
    TransformPersonToOrganizationCommand command,
  ) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_partner_id': command.partnerId,
      'p_organization_profile': _organizationInput(command.organizationProfile),
      'p_expected_version': command.expectedVersion,
      'p_confirm_duplicate': command.confirmDuplicate,
    };
  }

  static Map<String, dynamic> addContactParams(
    AddOrganizationContactCommand command,
  ) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_organization_partner_id': command.organizationPartnerId,
      'p_person_partner_id': command.personPartnerId,
      'p_new_person_profile': _personInput(command.newPersonProfile),
      'p_contact_role': command.contactRole,
      'p_is_primary': command.isPrimary,
    };
  }

  static Map<String, dynamic> updateContactParams(
    UpdateOrganizationContactCommand command,
  ) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_organization_partner_id': command.organizationPartnerId,
      'p_person_partner_id': command.personPartnerId,
      'p_contact_role': command.contactRole,
      'p_is_primary': command.isPrimary,
      'p_note': command.note,
      'p_person_profile': _personInput(command.personProfile),
    };
  }

  static Map<String, dynamic> removeContactParams(
    RemoveOrganizationContactCommand command,
  ) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_organization_partner_id': command.organizationPartnerId,
      'p_person_partner_id': command.personPartnerId,
    };
  }

  static Map<String, dynamic> deactivatePartnerParams(
    DeactivatePartnerCommand command,
  ) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_partner_id': command.partnerId,
      'p_reason': command.reason,
      'p_expected_version': command.expectedVersion,
    };
  }

  static Map<String, dynamic> reactivatePartnerParams(
    ReactivatePartnerCommand command,
  ) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_partner_id': command.partnerId,
      'p_reason': command.reason,
      'p_expected_version': command.expectedVersion,
    };
  }

  static Map<String, dynamic> softDeletePartnerParams(
    SoftDeletePartnerCommand command,
  ) {
    return <String, dynamic>{
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_partner_id': command.partnerId,
      'p_reason': command.reason,
      'p_expected_version': command.expectedVersion,
    };
  }

  static CreatePartnerResult mapCreatePartnerResult(Map<String, dynamic> row) {
    return CreatePartnerResult(
      partnerId: row['partner_id'] as String,
      warnings: _warnings(row['warnings']),
    );
  }

  static UpdatePartnerProfileResult mapUpdatePartnerResult(
    Map<String, dynamic> row,
  ) {
    return UpdatePartnerProfileResult(
      partnerId: row['partner_id'] as String,
      expectedVersion: row['expected_version'] as int,
      warnings: _warnings(row['warnings']),
    );
  }

  static TransformPartnerResult mapTransformPartnerResult(
    Map<String, dynamic> row,
  ) {
    return TransformPartnerResult(
      partnerId: row['partner_id'] as String,
    );
  }

  static AddOrganizationContactResult mapAddContactResult(
    Map<String, dynamic> row,
  ) {
    return AddOrganizationContactResult(
      organizationPartnerId: row['organization_partner_id'] as String,
      personPartnerId: row['person_partner_id'] as String,
    );
  }

  static DeactivatePartnerResult mapDeactivatePartnerResult(
    Map<String, dynamic> row,
  ) {
    return DeactivatePartnerResult(
      partnerId: row['partner_id'] as String,
      expectedVersion: row['expected_version'] as int,
    );
  }

  static ReactivatePartnerResult mapReactivatePartnerResult(
    Map<String, dynamic> row,
  ) {
    return ReactivatePartnerResult(
      partnerId: row['partner_id'] as String,
      expectedVersion: row['expected_version'] as int,
    );
  }

  static SoftDeletePartnerResult mapSoftDeletePartnerResult(
    Map<String, dynamic> row,
  ) {
    return SoftDeletePartnerResult(
      partnerId: row['partner_id'] as String,
      expectedVersion: row['expected_version'] as int,
    );
  }

  static Map<String, dynamic>? _personInput(PersonProfileInput? input) {
    if (input == null) {
      return null;
    }
    return <String, dynamic>{
      'title': input.title?.value,
      'full_name': input.fullName,
      'nickname': input.nickname,
      'phone': input.phone,
      'phone2': input.phone2,
      'email': input.email,
      'tax_code': input.taxCode,
      // Nested (current SQL) + flat (fallback / older SQL).
      'invoice': _invoiceNested(input.invoice),
      'invoice_name': input.invoice?.invoiceName,
      'invoice_address': input.invoice?.invoiceAddress,
      'invoice_email': input.invoice?.invoiceEmail,
      'delivery': _deliveryNested(input.delivery),
      'delivery_province': input.delivery?.province,
      'delivery_commune': input.delivery?.commune,
      'delivery_address': input.delivery?.address,
      'note': input.note,
    };
  }

  static Map<String, dynamic>? _organizationInput(
    OrganizationProfileInput? input,
  ) {
    if (input == null) {
      return null;
    }
    return <String, dynamic>{
      'organization_type': switch (input.organizationType) {
        OrganizationType.company => 'company',
        OrganizationType.businessHousehold => 'business_household',
        OrganizationType.other => 'other',
      },
      'organization_name': input.organizationName,
      'short_name': input.shortName,
      'intl_name': input.intlName,
      'phone': input.phone,
      'email': input.email,
      'tax_code': input.taxCode,
      'company_address': input.companyAddress,
      'invoice': _invoiceNested(input.invoice),
      'invoice_name': input.invoice?.invoiceName,
      'invoice_address': input.invoice?.invoiceAddress,
      'invoice_email': input.invoice?.invoiceEmail,
      'delivery': _deliveryNested(input.delivery),
      'delivery_province': input.delivery?.province,
      'delivery_commune': input.delivery?.commune,
      'delivery_address': input.delivery?.address,
      'note': input.note,
    };
  }

  /// Nested shape expected by `partner._insert_*_profile` (`invoice.name/address/email`).
  /// Also keep flat keys as fallback for older SQL that reads `invoice_address` at root.
  static Map<String, dynamic>? _invoiceNested(InvoiceProfileInput? invoice) {
    if (invoice == null) return null;
    return <String, dynamic>{
      'name': invoice.invoiceName,
      'address': invoice.invoiceAddress,
      'email': invoice.invoiceEmail,
    };
  }

  /// Nested shape expected by `partner._insert_*_profile` (`delivery.province/commune/address`).
  static Map<String, dynamic>? _deliveryNested(DeliveryAddressInput? delivery) {
    if (delivery == null) return null;
    return <String, dynamic>{
      'province': delivery.province,
      'commune': delivery.commune,
      'address': delivery.address,
    };
  }

  static List<PartnerWarningDto> _warnings(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return raw
        .map(
          (item) => PartnerWarningDto(
            code: (item as Map)['code'] as String,
            message: item['message'] as String? ?? '',
            field: item['field'] as String?,
          ),
        )
        .toList(growable: false);
  }
}
