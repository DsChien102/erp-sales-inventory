import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Product unit of measure (base or conversion).
final class ProductUnit extends Entity<String> implements IAggregateRoot {
  ProductUnit({
    required String id,
    required this.productId,
    required String name,
    required this.conversionRateToBase,
    required this.isBaseUnit,
    required this.isActive,
  }) : name = name.trim(),
       super(id: id) {
    if (id.trim().isEmpty) {
      throw DomainException('Product unit id must not be empty.');
    }
    if (productId.trim().isEmpty) {
      throw DomainException('Product id must not be empty.');
    }
    if (this.name.isEmpty) {
      throw DomainException('Product unit name must not be empty.');
    }
    if (conversionRateToBase <= 0) {
      throw DomainException('Conversion rate must be greater than zero.');
    }
    if (isBaseUnit && conversionRateToBase != 1) {
      throw DomainException('Base unit conversion rate must be 1.');
    }
  }

  final String productId;
  final String name;
  final double conversionRateToBase;
  final bool isBaseUnit;
  final bool isActive;

  factory ProductUnit.createBase({
    required String id,
    required String productId,
    required String name,
  }) {
    return ProductUnit(
      id: id,
      productId: productId,
      name: name,
      conversionRateToBase: 1,
      isBaseUnit: true,
      isActive: true,
    );
  }

  factory ProductUnit.createConversion({
    required String id,
    required String productId,
    required String name,
    required double conversionRateToBase,
  }) {
    return ProductUnit(
      id: id,
      productId: productId,
      name: name,
      conversionRateToBase: conversionRateToBase,
      isBaseUnit: false,
      isActive: true,
    );
  }

  ProductUnit activate() {
    return ProductUnit(
      id: id,
      productId: productId,
      name: name,
      conversionRateToBase: conversionRateToBase,
      isBaseUnit: isBaseUnit,
      isActive: true,
    );
  }

  ProductUnit deactivate() {
    return ProductUnit(
      id: id,
      productId: productId,
      name: name,
      conversionRateToBase: conversionRateToBase,
      isBaseUnit: isBaseUnit,
      isActive: false,
    );
  }

  String get normalizedName => normalizeName(name);

  static String normalizeName(String value) => value.trim().toLowerCase();
}
