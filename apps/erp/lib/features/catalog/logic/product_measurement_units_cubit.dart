import 'package:erp/core/errors/app_exception.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/measurement_unit_repository.dart';
import '../data/models.dart';
import 'catalog_error_messages.dart';
import 'product_measurement_units_state.dart';

class ProductMeasurementUnitsCubit extends Cubit<ProductMeasurementUnitsState> {
  ProductMeasurementUnitsCubit({
    required MeasurementUnitRepository measurementUnitRepository,
  })  : _measurementUnitRepository = measurementUnitRepository,
        super(const ProductMeasurementUnitsState());

  final MeasurementUnitRepository _measurementUnitRepository;

  void init(String productId, String? initialBaseUnitName) {
    emit(
      state.copyWith(
        productId: productId,
        baseUnitName: initialBaseUnitName,
      ),
    );
    loadTenantUnits();
    loadProductUnits();
  }

  Future<void> loadTenantUnits({String? keyword}) async {
    emit(state.copyWith(status: ProductMeasurementUnitsStatus.loading));
    try {
      final units = await _measurementUnitRepository.listTenantUnits(
        keyword: keyword,
        limit: 50,
      );
      emit(
        state.copyWith(
          status: ProductMeasurementUnitsStatus.success,
          tenantUnits: units,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ProductMeasurementUnitsStatus.failure,
          errorMessage: catalogErrorMessage(e),
        ),
      );
    }
  }

  Future<void> loadProductUnits() async {
    try {
      final productUnits = await _measurementUnitRepository.listProductUnits(
        state.productId,
        includeInactive: true,
      );
      emit(
        state.copyWith(
          productUnits: productUnits,
          baseUnitName: productUnits.baseUnitName,
        ),
      );
    } catch (_) {
      // It's okay if it fails (e.g., not found), we just don't have units yet.
    }
  }

  Future<void> setBaseUnitExisting(String unitId, String unitName) async {
    await _setBaseUnit(ExistingTenantUnit(unitId), unitName);
  }

  Future<void> setBaseUnitNew(String name) async {
    await _setBaseUnit(NewTenantUnit(name), name);
  }

  Future<void> _setBaseUnit(BaseUnitSelection selection, String displayUnitName) async {
    emit(state.copyWith(saveStatus: ProductMeasurementUnitsStatus.loading));
    try {
      await _measurementUnitRepository.setBaseUnit(
        state.productId,
        selection,
      );
      emit(
        state.copyWith(
          saveStatus: ProductMeasurementUnitsStatus.success,
          baseUnitName: displayUnitName,
        ),
      );
      // Reload units just in case a new unit was added
      loadTenantUnits();
      loadProductUnits();
    } catch (e) {
      emit(
        state.copyWith(
          saveStatus: ProductMeasurementUnitsStatus.failure,
          errorMessage: catalogErrorMessage(e),
        ),
      );
    }
  }

  Future<void> addConversionUnit(String unitName, double conversionRateToBase) async {
    emit(state.copyWith(unitMutationStatus: ProductMeasurementUnitsStatus.loading));
    try {
      await _measurementUnitRepository.addConversionUnit(
        productId: state.productId,
        unitName: unitName,
        conversionRateToBase: conversionRateToBase,
      );
      emit(state.copyWith(unitMutationStatus: ProductMeasurementUnitsStatus.success));
      await loadProductUnits();
    } catch (e) {
      emit(
        state.copyWith(
          unitMutationStatus: ProductMeasurementUnitsStatus.failure,
          errorMessage: catalogErrorMessage(e),
        ),
      );
    }
  }

  Future<void> deactivateConversionUnit(String productUnitId) async {
    emit(state.copyWith(unitMutationStatus: ProductMeasurementUnitsStatus.loading));
    try {
      await _measurementUnitRepository.deactivateConversionUnit(
        productId: state.productId,
        productUnitId: productUnitId,
      );
      emit(state.copyWith(unitMutationStatus: ProductMeasurementUnitsStatus.success));
      await loadProductUnits();
    } catch (e) {
      emit(
        state.copyWith(
          unitMutationStatus: ProductMeasurementUnitsStatus.failure,
          errorMessage: catalogErrorMessage(e),
        ),
      );
    }
  }

  Future<void> reactivateConversionUnit(String productUnitId) async {
    emit(state.copyWith(unitMutationStatus: ProductMeasurementUnitsStatus.loading));
    try {
      await _measurementUnitRepository.reactivateConversionUnit(
        productId: state.productId,
        productUnitId: productUnitId,
      );
      emit(state.copyWith(unitMutationStatus: ProductMeasurementUnitsStatus.success));
      await loadProductUnits();
    } catch (e) {
      emit(
        state.copyWith(
          unitMutationStatus: ProductMeasurementUnitsStatus.failure,
          errorMessage: catalogErrorMessage(e),
        ),
      );
    }
  }

  Future<void> deleteConversionUnit(String productUnitId) async {
    emit(
      state.copyWith(
        unitMutationStatus: ProductMeasurementUnitsStatus.loading,
        clearDeleteBlockedUnitId: true,
      ),
    );
    try {
      await _measurementUnitRepository.deleteConversionUnit(
        productId: state.productId,
        productUnitId: productUnitId,
      );
      emit(state.copyWith(unitMutationStatus: ProductMeasurementUnitsStatus.success));
      await loadProductUnits();
    } on AppException catch (e) {
      if (e.code == CatalogErrorCodes.conversionUnitDeleteBlocked) {
        emit(
          state.copyWith(
            unitMutationStatus: ProductMeasurementUnitsStatus.failure,
            errorMessage: catalogErrorMessage(e),
            deleteBlockedUnitId: productUnitId,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          unitMutationStatus: ProductMeasurementUnitsStatus.failure,
          errorMessage: catalogErrorMessage(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          unitMutationStatus: ProductMeasurementUnitsStatus.failure,
          errorMessage: catalogErrorMessage(e),
        ),
      );
    }
  }

  void clearDeleteBlocked() {
    emit(state.copyWith(clearDeleteBlockedUnitId: true));
  }
}
