import 'package:vet45_partner_domain/domain.dart';

import '../../shared/delivery_address_input.dart';
import '../../shared/invoice_profile_input.dart';

/// Read-model person profile fields.
final class PersonProfileDto {
  const PersonProfileDto({
    this.title,
    required this.fullName,
    this.nickname,
    required this.phone,
    this.phone2,
    this.email,
    this.taxCode,
    this.invoice,
    this.delivery,
    this.note,
  });

  /// Optional honorific — [PersonTitle] value object wrapping free-form user text.
  final PersonTitle? title;
  final String fullName;
  final String? nickname;
  final String phone;
  final String? phone2;
  final String? email;
  final String? taxCode;
  final InvoiceProfileInput? invoice;
  final DeliveryAddressInput? delivery;
  final String? note;
}
