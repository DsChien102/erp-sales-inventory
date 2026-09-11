import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_catalog_application/application.dart';

import 'product_manual_base_price_state.dart';

class ProductManualBasePriceCubit extends Cubit<ProductManualBasePriceState> {
  ProductManualBasePriceCubit({
    required IModuleMediator catalogModule,
    required IExecutionContext executionContext,
  }) : _catalogModule = catalogModule,
       _executionContext = executionContext,
       super(const ProductManualBasePriceState());

  final IModuleMediator _catalogModule;
  final IExecutionContext _executionContext;

  Future<void> submitManualBasePrice({
    required String productId,
    required double basePrice,
    String currency = 'VND',
  }) async {
    emit(state.copyWith(status: ProductManualBasePriceStatus.loading));
    try {
      final tenantId = await _executionContext.requireTenantId();
      final command = SetManualBasePriceCommand(
        tenantId: tenantId,
        productId: productId,
        basePrice: basePrice,
        currency: currency,
      );

      await _catalogModule.executeCommandAsync(command);

      emit(state.copyWith(status: ProductManualBasePriceStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: ProductManualBasePriceStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
