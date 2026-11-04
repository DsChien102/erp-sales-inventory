import 'package:erp/core/errors/app_exception.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/catalog_errors.dart';
import '../data/product_price_repository.dart';
import 'catalog_error_messages.dart';
import 'product_price_bands_state.dart';

class ProductPriceBandsCubit extends Cubit<ProductPriceBandsState> {
  ProductPriceBandsCubit({
    required ProductPriceRepository productPriceRepository,
    required this.productId,
  })  : _productPriceRepository = productPriceRepository,
        super(ProductPriceBandsInitial());

  final ProductPriceRepository _productPriceRepository;
  final String productId;

  Future<void> loadPriceBands() async {
    emit(ProductPriceBandsLoading());
    try {
      final result = await _productPriceRepository.listUnitPriceBands(productId);
      emit(ProductPriceBandsLoaded(result));
    } on AppException catch (e) {
      if (e.code == CatalogErrorCodes.missingBaseUnit) {
        emit(ProductPriceBandsMissingBaseUnit());
        return;
      }
      emit(ProductPriceBandsFailure(catalogErrorMessage(e)));
    } catch (e) {
      emit(ProductPriceBandsFailure(catalogErrorMessage(e)));
    }
  }
}
