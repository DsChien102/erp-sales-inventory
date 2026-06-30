import '../ids/business_partner_id.dart';
import '../shared/entity_type.dart';
import '../shared/partner_role.dart';
import '../shared/partner_status.dart';
import '../value_objects/address.dart';
import '../value_objects/bank_account.dart';
import '../value_objects/email_address.dart';
import '../value_objects/invoice_profile.dart';
import '../value_objects/partner_name.dart';
import '../value_objects/phone_number.dart';
import '../value_objects/tax_code.dart';
import 'business_partner_role.dart';
import 'events/partner_registered.dart';
import 'rules/entity_type_name_consistency_rule.dart';
import 'rules/partner_must_have_at_least_one_role_rule.dart';
import 'rules/partner_name_required_rule.dart';
import 'rules/phone_required_rule.dart';
import 'rules/tax_code_warning_rule.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class BusinessPartner extends Entity<BusinessPartnerId>
    implements IAggregateRoot {
  BusinessPartner._({
    required super.id,
    required this.tenantId,
    required this.entityType,
    required this.displayName,
    required this.phone,
    required this.roles,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedBy,
    required this.updatedAt,
    required this.version,
    this.individualName,
    this.businessName,
    this.companyName,
    this.email,
    this.taxCode,
    this.address,
    this.invoiceProfile,
    this.bankAccount,
    this.note,
  });

  factory BusinessPartner.register({
    required BusinessPartnerId id,
    required TenantId tenantId,
    required EntityType entityType,
    required PartnerName displayName,
    required PhoneNumber phone,
    required Set<PartnerRole> roles,
    required String actorId,
    DateTime? now,
    PartnerName? individualName,
    PartnerName? businessName,
    PartnerName? companyName,
    EmailAddress? email,
    TaxCode? taxCode,
    Address? address,
    InvoiceProfile? invoiceProfile,
    BankAccount? bankAccount,
    String? note,
  }) {
    final createdAt = now ?? DateTime.now();
    final partner = BusinessPartner._(
      id: id,
      tenantId: tenantId,
      entityType: entityType,
      displayName: displayName,
      individualName: individualName,
      businessName: businessName,
      companyName: companyName,
      phone: phone,
      email: email,
      taxCode: taxCode,
      address: address,
      invoiceProfile: invoiceProfile,
      bankAccount: bankAccount,
      roles: roles
          .map((role) => BusinessPartnerRole(role: role, createdAt: createdAt))
          .toList(growable: false),
      status: PartnerStatus.active,
      note: note?.trim().isEmpty ?? true ? null : note?.trim(),
      createdBy: actorId,
      createdAt: createdAt,
      updatedBy: actorId,
      updatedAt: createdAt,
      version: 1,
    );

    partner._validateRegisterInvariants();
    partner.addDomainEvent(
      PartnerRegistered(
        partnerId: id,
        tenantId: tenantId,
        entityType: entityType,
        roles: roles,
        displayName: displayName.value,
      ),
    );
    return partner;
  }

  final TenantId tenantId;
  final EntityType entityType;
  final PartnerName displayName;
  final PartnerName? individualName;
  final PartnerName? businessName;
  final PartnerName? companyName;
  final PhoneNumber phone;
  final EmailAddress? email;
  final TaxCode? taxCode;
  final Address? address;
  final InvoiceProfile? invoiceProfile;
  final BankAccount? bankAccount;
  final List<BusinessPartnerRole> roles;
  final PartnerStatus status;
  final String? note;

  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;
  final int version;

  bool get hasTaxCodeWarning => TaxCodeWarningRule(
        entityType: entityType,
        taxCode: taxCode,
      ).isWarning;

  bool hasRole(PartnerRole role) {
    return roles.any((item) => item.id == role && item.isActive);
  }

  void _validateRegisterInvariants() {
    checkRule(PartnerNameRequiredRule(displayName));
    checkRule(PhoneRequiredRule(phone));
    checkRule(
      PartnerMustHaveAtLeastOneRoleRule(
        roles.map((item) => item.id).toSet(),
      ),
    );
    checkRule(
      EntityTypeNameConsistencyRule(
        entityType: entityType,
        individualName: individualName,
        businessName: businessName,
        companyName: companyName,
      ),
    );
  }
}
