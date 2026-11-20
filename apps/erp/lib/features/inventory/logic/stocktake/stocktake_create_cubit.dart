import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/idempotency_key.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_repository.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_create_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StocktakeCreateCubit extends Cubit<StocktakeCreateState> {
  StocktakeCreateCubit({
    required StocktakeRepository repository,
    this.initialProductId,
    this.initialLotId,
    String Function() newKey = newIdempotencyKey,
  }) : _repository = repository,
       _newKey = newKey,
       super(const StocktakeCreateState());

  final StocktakeRepository _repository;
  final String? initialProductId;
  final String? initialLotId;
  final String Function() _newKey;

  String? _pendingOpenKey;

  Future<void> load() async {
    _pendingOpenKey = null;
    emit(const StocktakeCreateState(status: StocktakeCreateStatus.loading));
    try {
      final opts = await _repository.formOptions();
      final defaultCounter = opts.members.any((m) => m.userId == opts.me)
          ? opts.me
          : (opts.members.isNotEmpty ? opts.members.first.userId : opts.me);

      var scopeKind = StocktakeScopeKind.all;
      String? productId;
      String? lotId;

      if (initialLotId != null) {
        final matchedLot = opts.lots
            .where((l) => l.id == initialLotId)
            .firstOrNull;
        if (matchedLot != null) {
          scopeKind = StocktakeScopeKind.lot;
          lotId = matchedLot.id;
          productId = matchedLot.productId;
        }
      } else if (initialProductId != null) {
        final matchedProduct = opts.products
            .where((p) => p.id == initialProductId)
            .firstOrNull;
        if (matchedProduct != null) {
          scopeKind = StocktakeScopeKind.product;
          productId = matchedProduct.id;
        }
      }

      emit(
        StocktakeCreateState(
          status: StocktakeCreateStatus.ready,
          options: opts,
          scopeKind: scopeKind,
          selectedProductId: productId,
          selectedLotId: lotId,
          counterUserId: defaultCounter,
        ),
      );
    } catch (_) {
      emit(const StocktakeCreateState(status: StocktakeCreateStatus.loadError));
    }
  }

  void setScopeKind(StocktakeScopeKind kind) {
    if (kind == state.scopeKind) return;
    _pendingOpenKey = null;
    emit(
      state.copyWith(
        scopeKind: kind,
        clearSelectedProduct: true,
        clearSelectedLot: true,
        clearConflict: true,
        clearSubmitError: true,
        isScopeEmptyError: false,
      ),
    );
  }

  void selectProduct(String productId) {
    _pendingOpenKey = null;
    emit(
      state.copyWith(
        scopeKind: StocktakeScopeKind.product,
        selectedProductId: productId,
        clearSelectedLot: true,
        clearConflict: true,
        clearSubmitError: true,
        isScopeEmptyError: false,
      ),
    );
  }

  void selectLot(String lotId) {
    final lot = state.options?.lots.where((l) => l.id == lotId).firstOrNull;
    _pendingOpenKey = null;
    emit(
      state.copyWith(
        scopeKind: StocktakeScopeKind.lot,
        selectedLotId: lotId,
        selectedProductId: lot?.productId,
        clearConflict: true,
        clearSubmitError: true,
        isScopeEmptyError: false,
      ),
    );
  }

  void setCounter(String userId) {
    _pendingOpenKey = null;
    emit(
      state.copyWith(
        counterUserId: userId,
        clearSubmitError: true,
      ),
    );
  }

  void setReason(String reason) {
    _pendingOpenKey = null;
    emit(
      state.copyWith(
        reason: reason,
        reasonTouched: true,
        clearSubmitError: true,
      ),
    );
  }

  /// Tạo khoá idempotency một lần trước khi mở sheet xác nhận.
  void prepareOpenKey() {
    _pendingOpenKey ??= _newKey();
    emit(state.copyWith(clearSubmitError: true, isScopeEmptyError: false));
  }

  Future<void> submitOpen() async {
    if (state.blocker != null || state.status == StocktakeCreateStatus.submitting) {
      return;
    }
    final key = _pendingOpenKey ??= _newKey();
    emit(
      state.copyWith(
        status: StocktakeCreateStatus.submitting,
        clearConflict: true,
        clearSubmitError: true,
        isScopeEmptyError: false,
      ),
    );

    try {
      final result = await _repository.open(
        idempotencyKey: key,
        kind: state.scopeKind,
        productId: state.scopeKind == StocktakeScopeKind.product
            ? state.selectedProductId
            : null,
        lotId: state.scopeKind == StocktakeScopeKind.lot
            ? state.selectedLotId
            : null,
        counterUserId: state.counterUserId,
        reason: state.reason.trim(),
      );

      if (result.hasConflict) {
        _pendingOpenKey = null;
        emit(
          state.copyWith(
            status: StocktakeCreateStatus.ready,
            conflict: result.conflict,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: StocktakeCreateStatus.ready,
          openedSessionId: result.sessionId,
        ),
      );
    } catch (e) {
      final appError = AppException.from(e);
      final scopeEmpty =
          appError.code == InventoryErrorCode.stocktakeScopeEmpty;
      emit(
        state.copyWith(
          status: StocktakeCreateStatus.ready,
          submitError: inventoryErrorMessage(
            appError,
            fallback: appError.userMessage(),
          ),
          isScopeEmptyError: scopeEmpty,
        ),
      );
    }
  }
}

