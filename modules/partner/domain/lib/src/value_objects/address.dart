import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class Address extends ValueObject {
  Address(String value) : value = value.trim() {
    if (this.value.isEmpty) {
      throw DomainException('Address must not be empty.');
    }
  }

  final String value;

  @override
  List<Object?> get props => [value];
}
