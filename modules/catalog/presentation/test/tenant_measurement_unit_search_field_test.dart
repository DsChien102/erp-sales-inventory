import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/src/widgets/tenant_measurement_unit_search_field.dart';

void main() {
  const units = [
    TenantMeasurementUnitDto(id: 'unit-hop', name: 'Hộp'),
    TenantMeasurementUnitDto(id: 'unit-lo', name: 'Lọ'),
    TenantMeasurementUnitDto(id: 'unit-vi', name: 'Vỉ'),
  ];

  group('filterTenantMeasurementUnits', () {
    test('returns all units when query is blank', () {
      expect(filterTenantMeasurementUnits(units, ''), units);
      expect(filterTenantMeasurementUnits(units, '   '), units);
    });

    test('matches unit names without accents', () {
      expect(
        filterTenantMeasurementUnits(units, 'hop').map((unit) => unit.name),
        ['Hộp'],
      );
      expect(
        filterTenantMeasurementUnits(units, 'lo').map((unit) => unit.name),
        ['Lọ'],
      );
    });

    test('returns empty list when no unit matches', () {
      expect(filterTenantMeasurementUnits(units, 'xyz123'), isEmpty);
    });
  });

  group('excludeTenantMeasurementUnits', () {
    test('excludes already-added conversion units only', () {
      final available = excludeTenantMeasurementUnits(
        units,
        const ['Vỉ'],
      );

      expect(available.map((unit) => unit.name), containsAll(['Lọ', 'Hộp']));
      expect(available, hasLength(2));
    });
  });
}
