import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/product_price_repository.dart';
import 'catalog_error_messages.dart';
import 'store_price_rule_change_history_state.dart';

class StorePriceRuleChangeHistoryCubit extends Cubit<StorePriceRuleChangeHistoryState> {
  StorePriceRuleChangeHistoryCubit({
    required ProductPriceRepository productPriceRepository,
    this.pageSize = 50,
  })  : _productPriceRepository = productPriceRepository,
        super(StorePriceRuleChangeHistoryInitial());

  final ProductPriceRepository _productPriceRepository;
  final int pageSize;

  Future<void> load({bool refresh = true}) async {
    if (!refresh && state is StorePriceRuleChangeHistoryLoaded) {
      return;
    }
    emit(StorePriceRuleChangeHistoryLoading());
    try {
      final result = await _productPriceRepository.getStorePriceRuleHistory(
        limit: pageSize,
        offset: 0,
      );
      emit(
        StorePriceRuleChangeHistoryLoaded(
          items: result.items,
          totalCount: result.totalCount,
        ),
      );
    } catch (error) {
      emit(StorePriceRuleChangeHistoryError(message: catalogErrorMessage(error)));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! StorePriceRuleChangeHistoryLoaded ||
        !current.canLoadMore ||
        current.isLoadingMore) {
      return;
    }

    emit(
      StorePriceRuleChangeHistoryLoaded(
        items: current.items,
        totalCount: current.totalCount,
        isLoadingMore: true,
      ),
    );

    try {
      final result = await _productPriceRepository.getStorePriceRuleHistory(
        limit: pageSize,
        offset: current.items.length,
      );
      emit(
        StorePriceRuleChangeHistoryLoaded(
          items: [...current.items, ...result.items],
          totalCount: result.totalCount,
        ),
      );
    } catch (error) {
      emit(StorePriceRuleChangeHistoryError(message: catalogErrorMessage(error)));
    }
  }
}
