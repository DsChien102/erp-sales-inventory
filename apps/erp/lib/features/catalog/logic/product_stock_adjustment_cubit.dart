import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/product_repository.dart';
import 'catalog_error_messages.dart';
import 'product_stock_adjustment_state.dart';

String? combineStockAdjustmentReason({String? chip, required String note}) {
  final trimmedNote = note.trim();
  final hasChip = chip != null && chip.trim().isNotEmpty;
  final hasNote = trimmedNote.isNotEmpty;
  if (hasChip && hasNote) {
    return '$chip - $trimmedNote';
  } else if (hasChip) {
    return chip;
  } else if (hasNote) {
    return trimmedNote;
  }
  return null;
}

class ProductStockAdjustmentCubit extends Cubit<ProductStockAdjustmentState> {
  ProductStockAdjustmentCubit({
    required ProductRepository productRepository,
  })  : _productRepository = productRepository,
        super(const ProductStockAdjustmentState());

  final ProductRepository _productRepository;

  Future<void> submit({
    required String productId,
    required int quantity,
    int? currentQuantity,
    String? chip,
    String note = '',
  }) async {
    emit(state.copyWith(status: ProductStockAdjustmentStatus.loading));
    try {
      if (currentQuantity == null) {
        await _productRepository.setBasicStock(
          productId: productId,
          quantity: quantity,
        );
      } else {
        final reason = combineStockAdjustmentReason(chip: chip, note: note);
        await _productRepository.adjustBasicStock(
          productId: productId,
          newQuantity: quantity,
          reason: reason,
          expectedQuantity: currentQuantity,
        );
      }
      emit(state.copyWith(status: ProductStockAdjustmentStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: ProductStockAdjustmentStatus.failure,
          errorMessage: catalogErrorMessage(e),
        ),
      );
    }
  }
}

