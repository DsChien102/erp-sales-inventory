import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../rules/tax_code_must_not_be_blank_rule.dart';

/// Optional tax identification code.
final class TaxCode extends ValueObject {
  TaxCode(String raw) : value = raw.trim() {
    ValueObject.checkRule(TaxCodeMustNotBeBlankRule(value));
  }

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
