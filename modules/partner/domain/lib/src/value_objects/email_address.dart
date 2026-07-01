import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class EmailAddress extends ValueObject {
  EmailAddress(String value)
      : value = value.trim(),
        normalized = value.trim().toLowerCase() {
    if (!_emailRegex.hasMatch(this.value)) {
      throw DomainException('Email format is invalid.');
    }
  }

  final String value;
  final String normalized;

  static final RegExp _emailRegex = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$",
  );

  @override
  List<Object?> get props => [normalized];
}
