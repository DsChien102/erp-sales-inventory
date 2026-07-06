import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class ProductBaseUnit extends ValueObject {
  ProductBaseUnit(String name) : name = name.trim() {
    if (this.name.isEmpty) {
      throw DomainException('Base unit name must not be empty when provided.');
    }
  }

  final String name;
  final bool isBaseUnit = true;
  final double conversionRateToBase = 1;

  @override
  List<Object?> get props => [name, isBaseUnit, conversionRateToBase];
}
