import 'package:erp/core/errors/app_exception.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models.dart';
import '../data/product_repository.dart';
import 'catalog_error_messages.dart';
import 'product_control_center_state.dart';

class ProductControlCenterCubit extends Cubit<ProductControlCenterState> {
  ProductControlCenterCubit({
    required ProductRepository productRepository,
  })  : _productRepository = productRepository,
        super(const ProductControlCenterState());

  final ProductRepository _productRepository;

  Future<void> loadControlCenter(String productId) async {
    if (isClosed) return;
    emit(state.copyWith(status: ProductControlCenterStatus.loading));
    try {
      final controlCenter = await _productRepository.getControlCenter(productId);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProductControlCenterStatus.success,
          controlCenter: controlCenter,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProductControlCenterStatus.failure,
          errorMessage: catalogErrorMessage(e),
        ),
      );
    }
  }

  Future<void> loadReadinessForChecklist(String productId) async {
    if (isClosed) return;
    try {
      final readinessView = await _productRepository.getReadiness(productId);
      if (isClosed) return;
      emit(state.copyWith(readinessView: readinessView));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(errorMessage: catalogErrorMessage(e)));
    }
  }

  Future<void> deactivateProduct(
    String productId, {
    bool confirmAcknowledgeWarnings = false,
  }) async {
    if (isClosed) return;
    emit(
      state.copyWith(
        actionStatus: ProductLifecycleActionStatus.loading,
        clearActionWarnings: true,
      ),
    );
    try {
      await _productRepository.deactivate(
        productId: productId,
        confirmAcknowledgeWarnings: confirmAcknowledgeWarnings,
      );
      if (isClosed) return;

      emit(state.copyWith(actionStatus: ProductLifecycleActionStatus.success));
      await loadControlCenter(productId);
    } on AppException catch (e) {
      if (isClosed) return;
      if (e.code == CatalogErrorCodes.statusWarningsRequireAck) {
        final rawWarnings = e.details?['warnings'] as List<dynamic>? ?? const [];
        final warnings = rawWarnings
            .whereType<Map<String, dynamic>>()
            .map(ProductBusinessStatusWarningDto.fromJson)
            .toList();
        emit(
          state.copyWith(
            actionStatus: ProductLifecycleActionStatus.warning,
            actionWarnings: warnings,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          actionStatus: ProductLifecycleActionStatus.failure,
          actionErrorMessage: catalogErrorMessage(e),
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          actionStatus: ProductLifecycleActionStatus.failure,
          actionErrorMessage: catalogErrorMessage(e),
        ),
      );
    }
  }

  Future<void> reactivateProduct(String productId) async {
    if (isClosed) return;
    emit(
      state.copyWith(
        actionStatus: ProductLifecycleActionStatus.loading,
        clearActionWarnings: true,
      ),
    );
    try {
      await _productRepository.reactivate(productId: productId);
      if (isClosed) return;

      emit(state.copyWith(actionStatus: ProductLifecycleActionStatus.success));
      await loadControlCenter(productId);
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          actionStatus: ProductLifecycleActionStatus.failure,
          actionErrorMessage: catalogErrorMessage(e),
        ),
      );
    }
  }

  void resetActionState() {
    if (isClosed) return;
    emit(
      state.copyWith(
        actionStatus: ProductLifecycleActionStatus.initial,
        clearActionWarnings: true,
        actionErrorMessage: null,
      ),
    );
  }
}
