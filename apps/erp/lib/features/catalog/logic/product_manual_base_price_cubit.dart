import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/product_price_repository.dart';
import 'catalog_error_messages.dart';
import 'product_manual_base_price_state.dart';

class ProductManualBasePriceCubit extends Cubit<ProductManualBasePriceState> {
  ProductManualBasePriceCubit({
    required ProductPriceRepository productPriceRepository,
  })  : _productPriceRepository = productPriceRepository,
        super(const ProductManualBasePriceState());

  final ProductPriceRepository _productPriceRepository;

  Future<void> submitManualBasePrice({
    required String productId,
    required double basePrice,
    String currency = 'VND',
  }) async {
    emit(state.copyWith(status: ProductManualBasePriceStatus.loading));
    try {
      await _productPriceRepository.setManualBasePrice(
        productId: productId,
        basePrice: basePrice,
        currency: currency,
      );

      emit(state.copyWith(status: ProductManualBasePriceStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: ProductManualBasePriceStatus.failure,
          errorMessage: catalogErrorMessage(e),
        ),
      );
    }
  }
}
