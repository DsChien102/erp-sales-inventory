import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../rules/phone_must_not_be_blank_rule.dart';
import '../rules/phone_format_invalid_rule.dart';

/// Required phone number for partner profiles.
final class PhoneNumber extends ValueObject {
  PhoneNumber(String raw) : value = raw.trim() {
    ValueObject.checkRule(PhoneMustNotBeBlankRule(value));
    ValueObject.checkRule(PhoneFormatInvalidRule(value));
  }

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
