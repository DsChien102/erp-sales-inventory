import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/costing/costing_repository.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/logic/costing/cost_overview_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class CostOverviewCubit extends Cubit<CostOverviewState> {
  CostOverviewCubit(this._repo) : super(const CostOverviewState());

  final CostingRepository _repo;
  static const _uuid = Uuid();

  Future<void> load() async {
    emit(state.copyWith(status: CostOverviewStatus.loading, clearMessage: true));
    try {
      final data = await _repo.overview();
      if (isClosed) return;
      emit(state.copyWith(status: CostOverviewStatus.ready, data: data));
    } catch (e) {
      if (isClosed) return;
      final appEx = AppException.from(e);
      if (appEx.code == InventoryErrorCode.permissionDenied) {
        emit(state.copyWith(status: CostOverviewStatus.denied));
        return;
      }
      emit(
        state.copyWith(
          status: CostOverviewStatus.error,
          message: inventoryErrorMessage(
            appEx,
            fallback: 'Không tải được dữ liệu giá vốn.',
          ),
        ),
      );
    }
  }

  void selectFilter(CostRunFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  Future<bool> changeMethod(CostMethod method) async {
    if (state.savingMethod) return false;
    emit(state.copyWith(savingMethod: true, clearMessage: true));
    try {
      await _repo.setPolicy(idempotencyKey: _uuid.v4(), method: method);
      if (isClosed) return false;
      final fresh = await _repo.overview();
      if (isClosed) return true;
      emit(
        state.copyWith(
          status: CostOverviewStatus.ready,
          data: fresh,
          savingMethod: false,
        ),
      );
      return true;
    } catch (e) {
      if (isClosed) return false;
      final appEx = AppException.from(e);
      if (appEx.code == InventoryErrorCode.permissionDenied) {
        emit(
          state.copyWith(
            status: CostOverviewStatus.denied,
            savingMethod: false,
          ),
        );
        return false;
      }
      final msg = inventoryErrorMessage(
        appEx,
        fallback: 'Không đổi được phương pháp giá vốn.',
      );
      emit(state.copyWith(savingMethod: false, message: msg));
      if (appEx.code == InventoryErrorCode.costPolicyLocked) {
        try {
          final fresh = await _repo.overview();
          if (!isClosed) {
            emit(
              state.copyWith(
                status: CostOverviewStatus.ready,
                data: fresh,
              ),
            );
          }
        } catch (_) {}
      }
      return false;
    }
  }
}

