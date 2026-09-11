import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'product_control_center_state.dart';

class ProductControlCenterCubit extends Cubit<ProductControlCenterState> {
  ProductControlCenterCubit({
    required ICatalogModule catalogModule,
    required IExecutionContext executionContext,
  }) : _catalogModule = catalogModule,
       _executionContext = executionContext,
       super(const ProductControlCenterState());

  final ICatalogModule _catalogModule;
  final IExecutionContext _executionContext;

  Future<void> loadControlCenter(String productId) async {
    if (isClosed) return;
    emit(state.copyWith(status: ProductControlCenterStatus.loading));
    try {
      final tenantId = await _executionContext.requireTenantId();
      if (isClosed) return;
      final query = GetProductControlCenterQuery(
        tenantId: tenantId,
        productId: productId,
      );
      final controlCenter = await _catalogModule.executeQueryAsync(query);
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
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> loadReadinessForChecklist(String productId) async {
    if (isClosed) return;
    try {
      final tenantId = await _executionContext.requireTenantId();
      if (isClosed) return;
      final query = GetProductReadinessQuery(
        tenantId: tenantId,
        productId: productId,
      );
      final readinessView = await _catalogModule.executeQueryAsync(query);
      if (isClosed) return;
      emit(state.copyWith(readinessView: readinessView));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> deactivateProduct(
    String productId, {
    bool confirmAcknowledgeWarnings = false,
  }) async {
    if (isClosed) return;
    emit(
      state.copyWith(actionStatus: ProductLifecycleActionStatus.loading, clearActionWarnings: true),
    );
    try {
      final tenantId = await _executionContext.requireTenantId();
      if (isClosed) return;
      final actorId = await _executionContext.requireUserId();
      if (isClosed) return;

      final command = DeactivateProductCommand(
        tenantId: tenantId,
        actorId: actorId,
        productId: productId,
        confirmAcknowledgeWarnings: confirmAcknowledgeWarnings,
      );

      await _catalogModule.executeCommandAsync(command);
      if (isClosed) return;

      emit(state.copyWith(actionStatus: ProductLifecycleActionStatus.success));
      // Reload control center after success
      await loadControlCenter(productId);
    } on ProductBusinessStatusWarningsRequireAcknowledgmentException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          actionStatus: ProductLifecycleActionStatus.warning,
          actionWarnings: e.warnings,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          actionStatus: ProductLifecycleActionStatus.failure,
          actionErrorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> reactivateProduct(String productId) async {
    if (isClosed) return;
    emit(
      state.copyWith(actionStatus: ProductLifecycleActionStatus.loading, clearActionWarnings: true),
    );
    try {
      final tenantId = await _executionContext.requireTenantId();
      if (isClosed) return;
      final actorId = await _executionContext.requireUserId();
      if (isClosed) return;

      final command = ReactivateProductCommand(
        tenantId: tenantId,
        actorId: actorId,
        productId: productId,
      );

      await _catalogModule.executeCommandAsync(command);
      if (isClosed) return;

      emit(state.copyWith(actionStatus: ProductLifecycleActionStatus.success));
      // Reload control center after success
      await loadControlCenter(productId);
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          actionStatus: ProductLifecycleActionStatus.failure,
          actionErrorMessage: e.toString(),
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
