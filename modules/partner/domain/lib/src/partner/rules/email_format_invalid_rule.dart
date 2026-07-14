import 'package:vet45_shared_domain/shared_kernel_domain.dart';

class EmailFormatInvalidRule implements IBusinessRule {
  const EmailFormatInvalidRule(this.value);

  final String value;

  @override
  bool isBroken() {
    if (value.isEmpty) {
      return false;
    }
    return !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value);
  }

  @override
  String get message => 'Email format is invalid';
}
