import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/valuation_repository.dart';
import 'valuation_queue_state.dart';

class ValuationQueueCubit extends Cubit<ValuationQueueState> {
  ValuationQueueCubit({required ValuationRepository repository})
      : _repository = repository,
        super(const ValuationQueueState());

  final ValuationRepository _repository;

  Future<void> loadQueue() async {
    emit(state.copyWith(status: ValuationQueueStatus.loading));
    try {
      final items = await _repository.getQueue(
        query: state.query,
        filter: state.filter,
      );
      emit(state.copyWith(
        status: ValuationQueueStatus.success,
        items: items,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ValuationQueueStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> search(String query) async {
    emit(state.copyWith(query: query));
    await loadQueue();
  }

  Future<void> setFilter(String filter) async {
    emit(state.copyWith(filter: filter));
    await loadQueue();
  }
}
