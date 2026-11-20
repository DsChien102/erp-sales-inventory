import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/measurement_unit_repository.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/logic/product_measurement_units_cubit.dart';
import 'package:erp/features/catalog/logic/product_measurement_units_state.dart';
import 'package:flutter_test/flutter_test.dart';

final class _MockMeasurementUnitRepository extends Fake implements MeasurementUnitRepository {
  _MockMeasurementUnitRepository({
    this.onAddConversionUnit,
    this.onDeleteConversionUnit,
  });

  final Future<void> Function({
    required String productId,
    required String unitName,
    required double conversionRateToBase,
  })? onAddConversionUnit;

  final Future<void> Function({
    required String productId,
    required String productUnitId,
  })? onDeleteConversionUnit;

  @override
  Future<ProductUnitsDto> listProductUnits(String productId, {bool includeInactive = false}) async {
    return const ProductUnitsDto(
      productId: 'prod-1',
      baseUnitName: 'Lọ',
      units: [],
    );
  }

  @override
  Future<void> addConversionUnit({
    required String productId,
    required String unitName,
    required double conversionRateToBase,
  }) async {
    if (onAddConversionUnit != null) {
      return onAddConversionUnit!(
        productId: productId,
        unitName: unitName,
        conversionRateToBase: conversionRateToBase,
      );
    }
    throw UnimplementedError();
  }

  @override
  Future<void> deleteConversionUnit({
    required String productId,
    required String productUnitId,
  }) async {
    if (onDeleteConversionUnit != null) {
      return onDeleteConversionUnit!(
        productId: productId,
        productUnitId: productUnitId,
      );
    }
    throw UnimplementedError();
  }
}

void main() {
  group('ProductMeasurementUnitsCubit (H10)', () {
    test('1. delete conversion unit blocked sets deleteBlockedUnitId and server message', () async {
      final repo = _MockMeasurementUnitRepository(
        onDeleteConversionUnit: ({required productId, required productUnitId}) async {
          throw const AppException(
            CatalogErrorCodes.conversionUnitDeleteBlocked,
            serverMessage: 'Đơn vị đã được dùng trong bảng giá.',
          );
        },
      );

      final cubit = ProductMeasurementUnitsCubit(measurementUnitRepository: repo);
      cubit.init('prod-1', 'Lọ');

      await cubit.deleteConversionUnit('unit-hop');

      expect(cubit.state.unitMutationStatus, ProductMeasurementUnitsStatus.failure);
      expect(cubit.state.deleteBlockedUnitId, 'unit-hop');
      expect(cubit.state.errorMessage, contains('Đơn vị đã được dùng trong bảng giá.'));
    });

    test('2. add conversion unit with duplicate name shows duplicate error message', () async {
      final repo = _MockMeasurementUnitRepository(
        onAddConversionUnit: ({required productId, required unitName, required conversionRateToBase}) async {
          throw const AppException(
            CatalogErrorCodes.duplicateProductUnit,
            details: {'value': 'hộp'},
          );
        },
      );

      final cubit = ProductMeasurementUnitsCubit(measurementUnitRepository: repo);
      cubit.init('prod-1', 'Lọ');

      await cubit.addConversionUnit('hộp', 10.0);

      expect(cubit.state.unitMutationStatus, ProductMeasurementUnitsStatus.failure);
      expect(cubit.state.errorMessage, 'Đơn vị "hộp" đã có trong sản phẩm.');
    });
  });
}
