import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_repository.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';

class StocktakeListCubit extends Cubit<StocktakeListState> {
  StocktakeListCubit({required StocktakeRepository repository})
    : _repository = repository,
      super(const StocktakeListState());

  final StocktakeRepository _repository;

  Future<void> load() async {
    if (state.all.isEmpty) {
      emit(state.copyWith(status: StocktakeListStatus.loading, clearError: true));
    }
    try {
      final rows = await _repository.list();
      _emitFiltered(
        status: StocktakeListStatus.ready,
        all: rows,
        query: state.query,
        filter: state.filter,
      );
    } catch (e) {
      final appError = AppException.from(e);
      emit(
        state.copyWith(
          status: StocktakeListStatus.loadError,
          errorMessage: inventoryErrorMessage(
            appError,
            fallback: appError.userMessage(),
          ),
        ),
      );
    }
  }

  void setQuery(String query) {
    _emitFiltered(
      status: state.status,
      all: state.all,
      query: query,
      filter: state.filter,
    );
  }

  void setFilter(StocktakeListFilter filter) {
    _emitFiltered(
      status: state.status,
      all: state.all,
      query: state.query,
      filter: filter,
    );
  }

  void clearFilter() {
    _emitFiltered(
      status: state.status,
      all: state.all,
      query: '',
      filter: StocktakeListFilter.all,
    );
  }

  void _emitFiltered({
    required StocktakeListStatus status,
    required List<StocktakeListRow> all,
    required String query,
    required StocktakeListFilter filter,
  }) {
    final normalized = VTextNormalizer.normalizeForSearch(query.trim());
    final visible = all.where((row) {
      if (!filter.matches(row)) return false;
      if (normalized.isEmpty) return true;
      final hay = VTextNormalizer.normalizeForSearch(
        '${row.code} ${row.scopeLabel} ${row.counterName}',
      );
      return hay.contains(normalized);
    }).toList(growable: false);

    final counts = {
      for (final f in StocktakeListFilter.values)
        f: all.where(f.matches).length,
    };

    emit(
      state.copyWith(
        status: status,
        all: all,
        visible: visible,
        query: query,
        filter: filter,
        counts: counts,
        clearError: true,
      ),
    );
  }
}

