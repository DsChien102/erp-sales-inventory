import 'package:test/test.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('ProductUnitSet', () {
    ProductUnit baseUnit() => ProductUnit(
      id: 'product-1-base',
      productId: 'product-1',
      name: 'Hộp',
      conversionRateToBase: 1,
      isBaseUnit: true,
      isActive: true,
    );

    ProductUnit activeVi() => ProductUnit(
      id: 'product-1-unit-vi',
      productId: 'product-1',
      name: 'Vỉ',
      conversionRateToBase: 10,
      isBaseUnit: false,
      isActive: true,
    );

    ProductUnit inactiveThung() => ProductUnit(
      id: 'product-1-unit-thung',
      productId: 'product-1',
      name: 'Thùng',
      conversionRateToBase: 100,
      isBaseUnit: false,
      isActive: false,
    );

    test('adds conversion unit when product has base unit and no active duplicate', () {
      final set = ProductUnitSet(
        productId: 'product-1',
        units: [baseUnit(), activeVi()],
      );

      final unit = set.addConversionUnit(
        id: 'product-1-unit-new',
        name: 'Thùng',
        conversionRateToBase: 100,
      );

      expect(unit.id, 'product-1-unit-new');
      expect(unit.name, 'Thùng');
      expect(unit.conversionRateToBase, 100);
      expect(unit.isBaseUnit, isFalse);
      expect(unit.isActive, isTrue);
    });

    test('add conversion without base unit throws MissingBaseUnitException', () {
      final set = ProductUnitSet(
        productId: 'product-6',
        units: const [],
      );

      expect(
        () => set.addConversionUnit(
          id: 'product-6-unit-new',
          name: 'Hộp',
          conversionRateToBase: 10,
        ),
        throwsA(isA<MissingBaseUnitException>()),
      );
    });

    test('add conversion with zero or negative rate throws DomainException', () {
      final set = ProductUnitSet(
        productId: 'product-1',
        units: [baseUnit()],
      );

      expect(
        () => set.addConversionUnit(
          id: 'product-1-unit-zero',
          name: 'Vỉ',
          conversionRateToBase: 0,
        ),
        throwsA(isA<DomainException>()),
      );
      expect(
        () => set.addConversionUnit(
          id: 'product-1-unit-negative',
          name: 'Thùng',
          conversionRateToBase: -1,
        ),
        throwsA(isA<DomainException>()),
      );
    });

    test('add conversion rejects active duplicate or base unit name', () {
      final set = ProductUnitSet(
        productId: 'product-1',
        units: [baseUnit(), activeVi(), inactiveThung()],
      );

      expect(
        () => set.addConversionUnit(
          id: 'product-1-unit-dup-vi',
          name: ' vỉ ',
          conversionRateToBase: 10,
        ),
        throwsA(isA<DuplicateMeasurementUnitNameException>()),
      );
      expect(
        () => set.addConversionUnit(
          id: 'product-1-unit-dup-base',
          name: 'hộp',
          conversionRateToBase: 1,
        ),
        throwsA(isA<DuplicateMeasurementUnitNameException>()),
      );
    });

    test('deactivates active conversion unit', () {
      final set = ProductUnitSet(
        productId: 'product-1',
        units: [baseUnit(), activeVi()],
      );

      final unit = set.deactivateConversionUnit('product-1-unit-vi');

      expect(unit.id, 'product-1-unit-vi');
      expect(unit.isActive, isFalse);
    });

    test('deactivating base unit throws DomainException', () {
      final set = ProductUnitSet(
        productId: 'product-1',
        units: [baseUnit(), activeVi()],
      );

      expect(
        () => set.deactivateConversionUnit('product-1-base'),
        throwsA(isA<DomainException>()),
      );
    });

    test('reactivates inactive conversion unit', () {
      final set = ProductUnitSet(
        productId: 'product-1',
        units: [baseUnit(), inactiveThung()],
      );

      final unit = set.reactivateConversionUnit('product-1-unit-thung');

      expect(unit.id, 'product-1-unit-thung');
      expect(unit.isActive, isTrue);
    });

    test(
      'reactivating when active duplicate exists throws DuplicateMeasurementUnitNameException',
      () {
        final set = ProductUnitSet(
          productId: 'product-1',
          units: [
            baseUnit(),
            inactiveThung(),
            ProductUnit(
              id: 'product-1-unit-active-thung',
              productId: 'product-1',
              name: 'thùng',
              conversionRateToBase: 100,
              isBaseUnit: false,
              isActive: true,
            ),
          ],
        );

        expect(
          () => set.reactivateConversionUnit('product-1-unit-thung'),
          throwsA(isA<DuplicateMeasurementUnitNameException>()),
        );
      },
    );
  });
}
