import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Validates contact phone: 8–15 digits after removing separators.
final class ContactPhoneFormatRule implements IBusinessRule {
  ContactPhoneFormatRule(this._phone);

  final String _phone;

  @override
  bool isBroken() {
    final digits = _phone.replaceAll(RegExp(r'[\s\-().+]'), '');
    if (digits.isEmpty) {
      return true;
    }
    if (!RegExp(r'^\d+$').hasMatch(digits)) {
      return true;
    }
    return digits.length < 8 || digits.length > 15;
  }

  @override
  String get message => 'Contact phone format is invalid';
}
