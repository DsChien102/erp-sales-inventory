import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class Barcode extends ValueObject {
  Barcode(String value) : value = value.trim() {
    if (this.value.isEmpty) {
      throw DomainException('Barcode must not be empty when provided.');
    }
  }

  final String value;

  @override
  List<Object?> get props => [value];
}
