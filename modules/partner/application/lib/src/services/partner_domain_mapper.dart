import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../partner/commands/create_partner/create_partner_command.dart';
import '../partner/shared/delivery_address_input.dart';
import '../partner/shared/invoice_profile_input.dart';
import '../partner/shared/organization_profile_input.dart';
import '../partner/shared/person_profile_input.dart';

/// Maps application inputs to domain types and validates invariants.
abstract final class PartnerDomainMapper {
  static PersonProfile? toPersonProfile(PersonProfileInput? input) {
    if (input == null) {
      return null;
    }
    return PersonProfile(
      title: input.title,
      fullName: input.fullName,
      nickname: input.nickname,
      phone: PhoneNumber(input.phone),
      phone2: input.phone2 == null ? null : PhoneNumber(input.phone2!),
      email: input.email == null ? null : EmailAddress(input.email!),
      taxCode: input.taxCode == null ? null : TaxCode(input.taxCode!),
      invoice: _toInvoice(input.invoice),
      delivery: _toDelivery(input.delivery),
      note: input.note,
    );
  }

  static OrganizationProfile? toOrganizationProfile(
    OrganizationProfileInput? input,
  ) {
    if (input == null) {
      return null;
    }
    return OrganizationProfile(
      organizationType: input.organizationType,
      organizationName: input.organizationName,
      shortName: input.shortName,
      intlName: input.intlName,
      phone: PhoneNumber(input.phone),
      email: input.email == null ? null : EmailAddress(input.email!),
      taxCode: input.taxCode == null ? null : TaxCode(input.taxCode!),
      companyAddress: input.companyAddress,
      invoice: _toInvoice(input.invoice),
      delivery: _toDelivery(input.delivery),
      note: input.note,
    );
  }

  static Partner validateCreate(CreatePartnerCommand command) {
    return Partner.create(
      tenantId: TenantId(command.tenantId),
      partnerType: command.partnerType,
      roleTypes: command.roles,
      personProfile: toPersonProfile(command.personProfile),
      organizationProfile: toOrganizationProfile(command.organizationProfile),
    );
  }

  static InvoiceProfile? _toInvoice(InvoiceProfileInput? input) {
    if (input == null) {
      return null;
    }
    return InvoiceProfile(
      invoiceName: input.invoiceName,
      invoiceAddress: input.invoiceAddress,
      invoiceEmail: input.invoiceEmail == null
          ? null
          : EmailAddress(input.invoiceEmail!),
    );
  }

  static DeliveryAddress? _toDelivery(DeliveryAddressInput? input) {
    if (input == null) {
      return null;
    }
    return DeliveryAddress(
      province: input.province,
      commune: input.commune,
      address: input.address,
    );
  }
}
