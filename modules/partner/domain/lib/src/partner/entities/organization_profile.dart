import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/organization_type.dart';
import '../value_objects/delivery_address.dart';
import '../value_objects/email_address.dart';
import '../value_objects/invoice_profile.dart';
import '../value_objects/phone_number.dart';
import '../value_objects/tax_code.dart';
import '../rules/partner_display_name_must_not_be_blank_rule.dart';

/// Organization profile entity within the Partner aggregate.
final class OrganizationProfile extends ValueObject {
  OrganizationProfile({
    required this.organizationType,
    required String organizationName,
    this.shortName,
    this.intlName,
    required this.phone,
    this.email,
    this.taxCode,
    this.companyAddress,
    this.invoice,
    this.delivery,
    this.note,
  }) : organizationName = organizationName.trim() {
    ValueObject.checkRule(
      PartnerDisplayNameMustNotBeBlankRule(organizationName),
    );
  }

  final OrganizationType organizationType;
  final String organizationName;
  final String? shortName;
  final String? intlName;
  final PhoneNumber phone;
  final EmailAddress? email;
  final TaxCode? taxCode;
  final String? companyAddress;
  final InvoiceProfile? invoice;
  final DeliveryAddress? delivery;
  final String? note;

  @override
  List<Object?> get props => [
    organizationType,
    organizationName,
    shortName,
    intlName,
    phone,
    email,
    taxCode,
    companyAddress,
    invoice,
    delivery,
    note,
  ];
}
