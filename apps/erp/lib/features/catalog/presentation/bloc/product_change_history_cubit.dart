import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_change_history_state.dart';

class ProductChangeHistoryCubit extends Cubit<ProductChangeHistoryState> {
  final ICatalogModule _catalogModule;
  final IExecutionContext _executionContext;
  static const int _limit = 20;

  ProductChangeHistoryCubit({
    required ICatalogModule catalogModule,
    required IExecutionContext executionContext,
  }) : _catalogModule = catalogModule,
       _executionContext = executionContext,
       super(const ProductChangeHistoryState());

  Future<void> loadHistory(String productId) async {
    if (state.hasReachedMax) return;

    try {
      if (state.status == ProductChangeHistoryStatus.initial) {
        emit(state.copyWith(status: ProductChangeHistoryStatus.loading));
      }

      final tenantId = await _executionContext.requireTenantId();
      final query = GetProductChangeHistoryQuery(
        tenantId: tenantId,
        productId: productId,
        limit: _limit,
        offset: state.offset,
      );

      final result = await _catalogModule.executeQueryAsync<ProductChangeHistoryResultDto>(query);

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
    } on ApplicationException catch (e) {
      emit(
        state.copyWith(
          status: ProductChangeHistoryStatus.failure,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ProductChangeHistoryStatus.failure,
          errorMessage: 'Đã xảy ra lỗi không xác định',
        ),
      );
    }
  }

  void refresh(String productId) {
    emit(const ProductChangeHistoryState());
    loadHistory(productId);
  }
}
