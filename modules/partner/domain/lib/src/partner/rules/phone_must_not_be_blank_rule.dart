import 'package:vet45_shared_domain/shared_kernel_domain.dart';

class PhoneMustNotBeBlankRule implements IBusinessRule {
  const PhoneMustNotBeBlankRule(this.value);

  final String value;

  @override
  bool isBroken() => value.trim().isEmpty;

  @override
  String get message => 'Phone is required';
}
