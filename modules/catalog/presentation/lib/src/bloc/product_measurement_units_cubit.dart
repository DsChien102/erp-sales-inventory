import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'product_measurement_units_state.dart';

class ProductMeasurementUnitsCubit extends Cubit<ProductMeasurementUnitsState> {
  ProductMeasurementUnitsCubit({
    required ICatalogModule catalogModule,
    required IExecutionContext executionContext,
  })  : _catalogModule = catalogModule,
        _executionContext = executionContext,
        super(const ProductMeasurementUnitsState());

  final ICatalogModule _catalogModule;
  final IExecutionContext _executionContext;

  void init(String productId, String? initialBaseUnitName) {
    emit(state.copyWith(
      productId: productId,
      baseUnitName: initialBaseUnitName,
    ));
    loadTenantUnits();
  }

  Future<void> loadTenantUnits({String? keyword}) async {
    emit(state.copyWith(status: ProductMeasurementUnitsStatus.loading));
    try {
      final tenantId = await _executionContext.requireTenantId();
      final query = ListTenantMeasurementUnitsQuery(
        tenantId: tenantId,
        keyword: keyword,
        limit: 50,
      );
      final units = await _catalogModule.executeQueryAsync(query);
      emit(state.copyWith(
        status: ProductMeasurementUnitsStatus.success,
        tenantUnits: units,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProductMeasurementUnitsStatus.failure,
        errorMessage: e.toString(),
      ));
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
      final tenantId = await _executionContext.requireTenantId();
      final command = SetProductBaseUnitCommand(
        tenantId: tenantId,
        productId: state.productId,
        selection: selection,
      );
      await _catalogModule.executeCommandAsync(command);
      emit(state.copyWith(
        saveStatus: ProductMeasurementUnitsStatus.success,
        baseUnitName: displayUnitName,
      ));
      // Reload units just in case a new unit was added
      loadTenantUnits();
    } catch (e) {
      emit(state.copyWith(
        saveStatus: ProductMeasurementUnitsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
