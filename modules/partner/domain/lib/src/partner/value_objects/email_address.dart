import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../rules/email_format_invalid_rule.dart';

/// Optional email address with format validation.
final class EmailAddress extends ValueObject {
  EmailAddress(String raw) : value = raw.trim() {
    ValueObject.checkRule(EmailFormatInvalidRule(value));
  }

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
