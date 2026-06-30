import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class PhoneNumber extends ValueObject {
  PhoneNumber(String value)
      : value = value.trim(),
        normalized = _normalize(value) {
    if (this.value.isEmpty) {
      throw DomainException('Phone number is required.');
    }
    if (normalized.length < 8 || normalized.length > 15) {
      throw DomainException('Phone number format is invalid.');
    }
  }

  final String value;
  final String normalized;

  static String _normalize(String raw) {
    final trimmed = raw.trim();
    final withPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    return withPlus ? '+$digits' : digits;
  }

  @override
  List<Object?> get props => [normalized];
}
