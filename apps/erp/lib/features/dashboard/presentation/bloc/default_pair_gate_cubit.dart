import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_inventory_application/application.dart';
import 'package:vet45_shared_application/application.dart';

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
  DefaultPairGateCubit({required IInventoryModule inventoryModule})
    : _inventoryModule = inventoryModule,
      super(const DefaultPairGateState.loading());

  final IInventoryModule _inventoryModule;

  Future<void> load() async {
    emit(const DefaultPairGateState.loading());
    try {
      await _inventoryModule.executeQueryAsync(
        GetDefaultStoreWarehousePairQuery(),
      );
      if (isClosed) return;
      emit(const DefaultPairGateState.ready());
    } on ApplicationException catch (error) {
      if (error.message != 'DEFAULT_PAIR_MISSING') {
        _emitError(error.message);
        return;
      }
      await _ensure();
    } catch (error) {
      _emitError('$error');
    }
  }

  Future<void> _ensure() async {
    try {
      await _inventoryModule.executeCommandAsync(
        EnsureDefaultStoreWarehousePairCommand(),
      );
      if (isClosed) return;
      emit(const DefaultPairGateState.ready());
    } on ApplicationException catch (error) {
      _emitError(error.message);
    } catch (error) {
      _emitError('$error');
    }
  }

  void _emitError(String message) {
    if (isClosed) return;
    emit(DefaultPairGateState.error(message));
  }
}
