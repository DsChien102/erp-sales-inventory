import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class TaxCode extends ValueObject {
  TaxCode(String value)
      : value = value.trim(),
        normalized = value.trim().replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toUpperCase() {
    final trimmed = value.trim();
    if (!RegExp(r'^[0-9A-Za-z]+$').hasMatch(trimmed)) {
      throw DomainException('Tax code must only contain alphanumeric characters.');
    }
    if (normalized.length < 8 || normalized.length > 16) {
      throw DomainException('Tax code format is invalid.');
    }
  }

  final String value;
  final String normalized;

  @override
  List<Object?> get props => [normalized];
}
