import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../data/default_pair_repository.dart';

enum DefaultPairGateStatus { loading, ready, error }

final class DefaultPairGateState {
  const DefaultPairGateState._(this.status, this.failureMessage);

  const DefaultPairGateState.loading() : this._(DefaultPairGateStatus.loading, null);

  const DefaultPairGateState.ready() : this._(DefaultPairGateStatus.ready, null);

  const DefaultPairGateState.error(String failureMessage)
    : this._(DefaultPairGateStatus.error, failureMessage);

  final DefaultPairGateStatus status;
  final String? failureMessage;
}

final class DefaultPairGateCubit extends Cubit<DefaultPairGateState> {
  DefaultPairGateCubit({required DefaultPairRepository repository})
    : _repository = repository,
      super(const DefaultPairGateState.loading());

  final DefaultPairRepository _repository;

  Future<void> load() async {
    emit(const DefaultPairGateState.loading());
    try {
      await _repository.get();
      if (isClosed) return;
      emit(const DefaultPairGateState.ready());
    } on AppException catch (e) {
      if (e.code != 'DEFAULT_PAIR_MISSING') {
        _emitError(e.code);
        return;
      }
      await _ensure();
    } catch (error) {
      _emitError('$error');
    }
  }

  Future<void> _ensure() async {
    try {
      await _repository.ensure();
      if (isClosed) return;
      emit(const DefaultPairGateState.ready());
    } on AppException catch (e) {
      _emitError(e.code);
    } catch (error) {
      _emitError('$error');
    }
  }

  void _emitError(String message) {
    if (isClosed) return;
    emit(DefaultPairGateState.error(message));
  }
}
