import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'product_control_center_state.dart';

class ProductControlCenterCubit extends Cubit<ProductControlCenterState> {
  ProductControlCenterCubit({
    required ICatalogModule catalogModule,
    required IExecutionContext executionContext,
  })  : _catalogModule = catalogModule,
        _executionContext = executionContext,
        super(const ProductControlCenterState());

  final ICatalogModule _catalogModule;
  final IExecutionContext _executionContext;

  Future<void> loadReadiness(String productId) async {
    emit(state.copyWith(status: ProductControlCenterStatus.loading));
    try {
      final tenantId = await _executionContext.requireTenantId();
      final query = GetProductReadinessQuery(
        tenantId: tenantId,
        productId: productId,
      );
      final readinessView = await _catalogModule.executeQueryAsync(query);
      emit(state.copyWith(
        status: ProductControlCenterStatus.success,
        readinessView: readinessView,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProductControlCenterStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
