import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'store_price_rule_change_history_state.dart';

class StorePriceRuleChangeHistoryCubit
    extends Cubit<StorePriceRuleChangeHistoryState> {
  StorePriceRuleChangeHistoryCubit({
    required IModuleMediator moduleMediator,
    required IExecutionContext executionContext,
    this.pageSize = 50,
  })  : _moduleMediator = moduleMediator,
        _executionContext = executionContext,
        super(StorePriceRuleChangeHistoryInitial());

  final IModuleMediator _moduleMediator;
  final IExecutionContext _executionContext;
  final int pageSize;

  Future<void> load({bool refresh = true}) async {
    if (!refresh && state is StorePriceRuleChangeHistoryLoaded) {
      return;
    }
    emit(StorePriceRuleChangeHistoryLoading());
    try {
      final tenantId = await _executionContext.requireTenantId();
      final query = GetStorePriceRuleChangeHistoryQuery(
        tenantId: tenantId,
        limit: pageSize,
        offset: 0,
      );
      final result =
          await _moduleMediator.executeQueryAsync<
              StorePriceRuleChangeHistoryResultDto>(query);
      emit(
        StorePriceRuleChangeHistoryLoaded(
          items: result.items,
          totalCount: result.totalCount,
        ),
      );
    } catch (error) {
      emit(StorePriceRuleChangeHistoryError(message: error.toString()));
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
      final tenantId = await _executionContext.requireTenantId();
      final query = GetStorePriceRuleChangeHistoryQuery(
        tenantId: tenantId,
        limit: pageSize,
        offset: current.items.length,
      );
      final result =
          await _moduleMediator.executeQueryAsync<
              StorePriceRuleChangeHistoryResultDto>(query);
      emit(
        StorePriceRuleChangeHistoryLoaded(
          items: [...current.items, ...result.items],
          totalCount: result.totalCount,
        ),
      );
    } catch (error) {
      emit(StorePriceRuleChangeHistoryError(message: error.toString()));
    }
  }
}
