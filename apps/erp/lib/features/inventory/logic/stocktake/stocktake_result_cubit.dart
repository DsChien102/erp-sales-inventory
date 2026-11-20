import 'package:erp/features/inventory/data/stocktake/stocktake_repository.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_result_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StocktakeResultCubit extends Cubit<StocktakeResultState> {
  StocktakeResultCubit({
    required StocktakeRepository repository,
    required this.sessionId,
  }) : _repository = repository,
       super(const StocktakeResultState());

  final StocktakeRepository _repository;
  final String sessionId;

  Future<void> load() async {
    emit(const StocktakeResultState(status: StocktakeResultLoadStatus.loading));
    try {
      final session = await _repository.get(sessionId);
      emit(
        StocktakeResultState(
          status: StocktakeResultLoadStatus.ready,
          session: session,
        ),
      );
    } catch (_) {
      emit(const StocktakeResultState(status: StocktakeResultLoadStatus.error));
    }
  }
}

