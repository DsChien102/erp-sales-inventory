import 'package:vet45_shared_domain/shared_kernel_domain.dart';

class PartnerDisplayNameMustNotBeBlankRule implements IBusinessRule {
  const PartnerDisplayNameMustNotBeBlankRule(this.value);

  final String value;

  @override
  bool isBroken() => value.trim().isEmpty;

  @override
  String get message => 'Display name must not be blank';
}
