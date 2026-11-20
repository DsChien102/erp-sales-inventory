import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/stock/stock_repository.dart';
import 'package:erp/features/inventory/logic/stock/stale_watcher.dart';
import 'package:erp/features/inventory/logic/stock/stock_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StockDetailCubit extends Cubit<StockDetailState> {
  final StockRepository _repository;
  final StaleWatcher _stale;

  StockDetailCubit({
    required StockRepository repository,
    StaleWatcher? stale,
  })  : _repository = repository,
        _stale = stale ?? const StaleWatcher(),
        super(const StockDetailState());

  /// Đổi sang sản phẩm khác ⇒ bỏ dữ liệu sản phẩm cũ (không hiện nhầm trong lúc tải / khi lỗi).
  Future<void> load(String productId) async {
    final sameProduct = productId == state.productId;
    emit(
      StockDetailState(
        status: StockDetailStatus.loading,
        productId: productId,
        data: sameProduct ? state.data : null,
        stale: sameProduct && state.stale,
      ),
    );
    await _fetch(productId);
  }

  Future<void> refresh() async {
    final pid = state.productId ?? state.data?.productId;
    if (pid == null) return;
    await _fetch(pid);
  }

  Future<void> _fetch(String productId) async {
    try {
      final detail = await _repository.loadDetail(productId);
      // Phản hồi của sản phẩm đã bỏ chọn về muộn ⇒ bỏ qua.
      if (isClosed || state.productId != productId) return;
      emit(
        state.copyWith(
          status: StockDetailStatus.ready,
          productId: productId,
          data: detail,
          stale: false,
          clearError: true,
        ),
      );
    } catch (e) {
      if (isClosed || state.productId != productId) return;
      final appEx = AppException.from(e);
      if (appEx.isNoPermission ||
          appEx.code == InventoryErrorCode.permissionDenied ||
          appEx.code == 'PERMISSION_DENIED') {
        emit(state.copyWith(status: StockDetailStatus.denied, error: appEx));
      } else {
        emit(state.copyWith(status: StockDetailStatus.loadError, error: appEx));
      }
    }
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
