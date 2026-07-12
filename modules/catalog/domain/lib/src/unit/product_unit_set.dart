import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../exceptions/duplicate_measurement_unit_name_exception.dart';
import '../exceptions/missing_base_unit_exception.dart';
import 'product_unit.dart';

/// Collection helper enforcing conversion-unit invariants for a product.
final class ProductUnitSet {
  ProductUnitSet({
    required this.productId,
    required Iterable<ProductUnit> units,
  }) : units = List.unmodifiable(units) {
    if (productId.trim().isEmpty) {
      throw DomainException('Product id must not be empty.');
    }
    for (final unit in this.units) {
      if (unit.productId != productId) {
        throw DomainException('Product unit belongs to a different product.');
      }
    }
  }

  final String productId;
  final List<ProductUnit> units;

  bool get hasActiveBaseUnit => units.any(
    (unit) => unit.isBaseUnit && unit.isActive,
  );

  ProductUnit addConversionUnit({
    required String id,
    required String name,
    required double conversionRateToBase,
  }) {
    if (!hasActiveBaseUnit) {
      throw MissingBaseUnitException();
    }
    _ensureNoActiveDuplicate(name);

    return ProductUnit.createConversion(
      id: id,
      productId: productId,
      name: name,
      conversionRateToBase: conversionRateToBase,
    );
  }

  ProductUnit deactivateConversionUnit(String productUnitId) {
    final unit = _requireUnit(productUnitId);
    if (unit.isBaseUnit) {
      throw DomainException('Base unit cannot be deactivated here.');
    }
    return unit.deactivate();
  }

  ProductUnit reactivateConversionUnit(String productUnitId) {
    final unit = _requireUnit(productUnitId);
    if (unit.isBaseUnit) {
      throw DomainException('Base unit cannot be reactivated here.');
    }

    final duplicate = _findActiveDuplicate(unit.name, excludeUnitId: unit.id);
    if (duplicate != null) {
      throw DuplicateMeasurementUnitNameException(
        name: unit.name,
        existingUnitId: duplicate.id,
      );
    }
    return unit.activate();
  }

  ProductUnit deleteConversionUnit(String productUnitId) {
    final unit = _requireUnit(productUnitId);
    if (unit.isBaseUnit) {
      throw DomainException('Base unit cannot be deleted here.');
    }
    return unit;
  }

  ProductUnit _requireUnit(String productUnitId) {
    for (final unit in units) {
      if (unit.id == productUnitId) {
        return unit;
      }
    }
    throw DomainException('Product unit not found.');
  }

  void _ensureNoActiveDuplicate(String name) {
    final duplicate = _findActiveDuplicate(name);
    if (duplicate != null) {
      throw DuplicateMeasurementUnitNameException(
        name: name.trim(),
        existingUnitId: duplicate.id,
      );
    }
  }

  ProductUnit? _findActiveDuplicate(String name, {String? excludeUnitId}) {
    final normalizedName = ProductUnit.normalizeName(name);
    for (final unit in units) {
      if (unit.id == excludeUnitId || !unit.isActive) {
        continue;
      }
      if (unit.normalizedName == normalizedName) {
        return unit;
      }
    }
    return null;
  }
}
