import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../person_title.dart';
import '../value_objects/delivery_address.dart';
import '../value_objects/email_address.dart';
import '../value_objects/invoice_profile.dart';
import '../value_objects/phone_number.dart';
import '../value_objects/tax_code.dart';
import '../rules/partner_display_name_must_not_be_blank_rule.dart';

/// Person profile entity within the Partner aggregate.
final class PersonProfile extends ValueObject {
  PersonProfile({
    this.title,
    required String fullName,
    this.nickname,
    required this.phone,
    this.phone2,
    this.email,
    this.taxCode,
    this.invoice,
    this.delivery,
    this.note,
  }) : fullName = fullName.trim() {
    ValueObject.checkRule(PartnerDisplayNameMustNotBeBlankRule(fullName));
  }

  final PersonTitle? title;
  final String fullName;
  final String? nickname;
  final PhoneNumber phone;
  final PhoneNumber? phone2;
  final EmailAddress? email;
  final TaxCode? taxCode;
  final InvoiceProfile? invoice;
  final DeliveryAddress? delivery;
  final String? note;

  @override
  List<Object?> get props => [
    title,
    fullName,
    nickname,
    phone,
    phone2,
    email,
    taxCode,
    invoice,
    delivery,
    note,
  ];
}
