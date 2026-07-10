import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Phase 1: basic length check — detailed locale rules live in RPC.
class PhoneFormatInvalidRule implements IBusinessRule {
  const PhoneFormatInvalidRule(this.value);

  final String value;

  @override
  bool isBroken() {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length < 8 || digits.length > 15;
  }

  @override
  String get message => 'Phone format is invalid';
}
