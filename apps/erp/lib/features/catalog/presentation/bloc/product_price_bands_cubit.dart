import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_price_bands_state.dart';

class ProductPriceBandsCubit extends Cubit<ProductPriceBandsState> {
  ProductPriceBandsCubit({
    required this.moduleMediator,
    required this.executionContext,
    required this.productId,
  }) : super(ProductPriceBandsInitial());

  final IModuleMediator moduleMediator;
  final IExecutionContext executionContext;
  final String productId;

  Future<void> loadPriceBands() async {
    emit(ProductPriceBandsLoading());
    try {
      final tenantId = await executionContext.requireTenantId();
      final query = ListProductUnitPriceBandsQuery(tenantId: tenantId, productId: productId);
      final result = await moduleMediator.executeQueryAsync(query);
      emit(ProductPriceBandsLoaded(result));
    } on MissingBaseUnitException {
      emit(ProductPriceBandsMissingBaseUnit());
    } catch (e) {
      emit(ProductPriceBandsFailure(e.toString()));
    }
  }
}
