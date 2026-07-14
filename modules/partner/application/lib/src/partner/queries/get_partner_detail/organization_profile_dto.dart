import 'package:vet45_partner_domain/domain.dart';

import '../../shared/delivery_address_input.dart';
import '../../shared/invoice_profile_input.dart';

/// Read-model organization profile fields.
final class OrganizationProfileDto {
  const OrganizationProfileDto({
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
