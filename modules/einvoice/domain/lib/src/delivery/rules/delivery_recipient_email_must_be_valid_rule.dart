import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Email format for delivery recipients (trimmed value checked).
final class DeliveryRecipientEmailMustBeValidRule implements IBusinessRule {
  const DeliveryRecipientEmailMustBeValidRule(this.value);

  final String value;

  static final RegExp _pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  bool isBroken() {
    if (value.isEmpty) {
      return true;
    }
    return !_pattern.hasMatch(value);
  }

  @override
  String get message => 'Delivery recipient email must be a valid address';
}
