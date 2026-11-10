import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/stock/stock_repository.dart';
import 'package:erp/features/inventory/logic/stock/stale_watcher.dart';
import 'package:erp/features/inventory/logic/stock/stock_list_rules.dart';
import 'package:erp/features/inventory/logic/stock/stock_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StockListCubit extends Cubit<StockListState> {
  final StockRepository _repository;
  final StaleWatcher _stale;

  StockListCubit({
    required StockRepository repository,
    StaleWatcher? stale,
  })  : _repository = repository,
        _stale = stale ?? const StaleWatcher(),
        super(const StockListState());

  Future<void> load() async {
    emit(state.copyWith(status: StockListStatus.loading, clearError: true));
    await _fetch();
  }

  Future<void> refresh() async {
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final overview = await _repository.loadOverview();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: overview.products.isEmpty
              ? StockListStatus.empty
              : StockListStatus.ready,
          data: overview,
          stale: false,
          clearError: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final appEx = AppException.from(e);
      if (appEx.isNoPermission ||
          appEx.code == InventoryErrorCode.permissionDenied ||
          appEx.code == 'PERMISSION_DENIED') {
        emit(state.copyWith(status: StockListStatus.denied, error: appEx));
      } else {
        emit(state.copyWith(status: StockListStatus.loadError, error: appEx));
      }
    }
  }

  void setFilter(StockFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  void setQuery(String query) {
    emit(state.copyWith(query: query));
  }

  void clearSearchAndFilter() {
    emit(state.copyWith(filter: StockFilter.all, query: ''));
  }

  void select(String productId) {
    emit(state.copyWith(selectedProductId: productId));
  }

  void checkStale() {
    final currentData = state.data;
    if (currentData == null) return;
    final isStale = _stale.isStale(currentData.asOf);
    if (isStale != state.stale) {
      emit(state.copyWith(stale: isStale));
    }
  }
}
