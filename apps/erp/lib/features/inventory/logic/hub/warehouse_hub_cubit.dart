import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/hub/warehouse_hub_repository.dart';
import 'warehouse_hub_state.dart';

class WarehouseHubCubit extends Cubit<WarehouseHubState> {
  WarehouseHubCubit({
    required WarehouseHubRepository repository,
    required bool Function() isOwner,
  })  : _repository = repository,
        _isOwner = isOwner,
        super(const WarehouseHubLoading());

  final WarehouseHubRepository _repository;
  final bool Function() _isOwner;

  Future<void> load() async {
    emit(const WarehouseHubLoading());
    try {
      final summary = await _repository.getSummary();
      final owner = _isOwner();
      emit(WarehouseHubLoaded(summary: summary, isOwner: owner));
    } on AppException catch (e) {
      emit(WarehouseHubError(e.userMessage()));
    } catch (_) {
      emit(const WarehouseHubError('Không tải được dữ liệu. Thử lại.'));
    }
  }
}
