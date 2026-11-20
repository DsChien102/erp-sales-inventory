import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/product_repository.dart';
import 'catalog_error_messages.dart';
import 'product_change_history_state.dart';

class ProductChangeHistoryCubit extends Cubit<ProductChangeHistoryState> {
  final ProductRepository _productRepository;
  static const int _limit = 20;

  ProductChangeHistoryCubit({
    required ProductRepository productRepository,
  })  : _productRepository = productRepository,
        super(const ProductChangeHistoryState());

  Future<void> loadHistory(String productId) async {
    if (state.hasReachedMax) return;

    try {
      if (state.status == ProductChangeHistoryStatus.initial) {
        emit(state.copyWith(status: ProductChangeHistoryStatus.loading));
      }

      final result = await _productRepository.getChangeHistory(
        productId: productId,
        limit: _limit,
        offset: state.offset,
      );

      final newItems = List.of(state.items)..addAll(result.items);

      emit(
        state.copyWith(
          status: ProductChangeHistoryStatus.success,
          items: newItems,
          totalCount: result.totalCount,
          hasReachedMax: result.items.length < _limit,
          offset: state.offset + _limit,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ProductChangeHistoryStatus.failure,
          errorMessage: catalogErrorMessage(e, fallback: 'Đã xảy ra lỗi không xác định'),
        ),
      );
    }
  }

  void refresh(String productId) {
    emit(const ProductChangeHistoryState());
    loadHistory(productId);
  }
}
