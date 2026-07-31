import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Validates trimmed, lowercased contact email format.
final class ContactEmailFormatRule implements IBusinessRule {
  ContactEmailFormatRule(this._email);

  final String _email;

  static final _pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  bool isBroken() {
    final trimmed = _email.trim();
    if (trimmed.isEmpty) {
      return true;
    }
    return !_pattern.hasMatch(trimmed.toLowerCase());
  }

  @override
  String get message => 'Contact email format is invalid';
}
