import 'package:vet45_shared_domain/shared_kernel_domain.dart';

class TaxCodeMustNotBeBlankRule implements IBusinessRule {
  const TaxCodeMustNotBeBlankRule(this.value);

  final String value;

  @override
  bool isBroken() => value.trim().isEmpty;

  @override
  String get message => 'Tax code must not be blank when provided';
}
