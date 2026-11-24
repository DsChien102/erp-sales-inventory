import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../data/home_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required HomeRepository repository})
    : _repository = repository,
      super(const HomeState());

  final HomeRepository _repository;

  /// Số thứ tự lần tải mới nhất; kết quả của lần cũ hơn bị bỏ (đổi tổ chức khi đang tải).
  int _generation = 0;

  /// [reset]: đổi tổ chức → bỏ số của tổ chức cũ, hiện khung xương.
  Future<void> load({bool reset = false}) async {
    final gen = ++_generation;
    if (reset || (state.summary == null && state.status != HomeStatus.loading)) {
      emit(const HomeState());
    }
    try {
      final summary = await _repository.fetch();
      if (isClosed || gen != _generation) return;
      emit(HomeState(status: HomeStatus.ready, summary: summary));
    } catch (e, st) {
      if (isClosed || gen != _generation) return;
      final error = AppException.from(e, st);
      final kept = state.summary;
      if (kept != null) {
        emit(HomeState(status: HomeStatus.ready, summary: kept, refreshError: error));
      } else {
        emit(HomeState(status: HomeStatus.error, error: error));
      }
    }
  }
}
