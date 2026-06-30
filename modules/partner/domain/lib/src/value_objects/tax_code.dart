import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class TaxCode extends ValueObject {
  TaxCode(String value)
      : value = value.trim(),
        normalized = value.trim().replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toUpperCase() {
    if (normalized.isEmpty) {
      throw DomainException('Tax code must not be empty.');
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
