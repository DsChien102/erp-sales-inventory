import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/costing/costing_repository.dart';
import 'package:erp/features/inventory/logic/costing/cost_versions_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CostVersionsCubit extends Cubit<CostVersionsState> {
  CostVersionsCubit(this._repo) : super(const CostVersionsState());

  final CostingRepository _repo;

  Future<void> load(String productId) async {
    emit(const CostVersionsState(status: CostVersionsStatus.loading));
    try {
      final data = await _repo.versions(productId);
      if (isClosed) return;
      emit(CostVersionsState(status: CostVersionsStatus.ready, data: data));
    } catch (e) {
      if (isClosed) return;
      final appEx = AppException.from(e);
      emit(
        CostVersionsState(
          status: CostVersionsStatus.error,
          message: inventoryErrorMessage(
            appEx,
            fallback: 'Không tải được lịch sử giá vốn.',
          ),
        ),
      );
    }
  }
}

