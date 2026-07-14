import 'package:vet45_partner_domain/domain.dart';

import 'delivery_address_input.dart';
import 'invoice_profile_input.dart';

/// Organization profile payload for create/update/transform flows.
final class OrganizationProfileInput {
  const OrganizationProfileInput({
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
