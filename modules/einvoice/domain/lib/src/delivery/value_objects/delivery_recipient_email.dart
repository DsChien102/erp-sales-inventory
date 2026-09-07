import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../rules/delivery_recipient_email_must_be_valid_rule.dart';

/// Validated, trimmed recipient email for invoice delivery.
final class DeliveryRecipientEmail extends ValueObject {
  DeliveryRecipientEmail(String raw) : value = raw.trim() {
    ValueObject.checkRule(DeliveryRecipientEmailMustBeValidRule(value));
  }

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
