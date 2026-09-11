import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_soft_delete_state.dart';

class ProductSoftDeleteCubit extends Cubit<ProductSoftDeleteState> {
  ProductSoftDeleteCubit({
    required IModuleMediator mediator,
    required IExecutionContext executionContext,
  }) : _mediator = mediator,
       _executionContext = executionContext,
       super(const ProductSoftDeleteState());

  final IModuleMediator _mediator;
  final IExecutionContext _executionContext;

  Future<void> checkEligibility(String productId) async {
    emit(state.copyWith(status: ProductSoftDeleteStatus.checkingEligibility));
    try {
      final query = CheckProductDeletionEligibilityQuery(
        tenantId: await _executionContext.requireTenantId(),
        productId: productId,
      );
      final result = await _mediator.executeQueryAsync(query);
      emit(
        state.copyWith(
          status: ProductSoftDeleteStatus.eligibilityChecked,
          eligibility: result,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ProductSoftDeleteStatus.error,
          errorMessage: 'Không thể kiểm tra điều kiện xóa sản phẩm.',
        ),
      );
    }
  }

  Future<void> deleteProduct({
    required String productId,
    required bool confirmAcknowledgeWarnings,
    int? expectedVersion,
  }) async {
    emit(state.copyWith(status: ProductSoftDeleteStatus.deleting));
    try {
      final command = DeleteProductCommand(
        tenantId: await _executionContext.requireTenantId(),
        actorId: await _executionContext.requireUserId(),
        productId: productId,
        confirmAcknowledgeWarnings: confirmAcknowledgeWarnings,
        expectedVersion: expectedVersion,
      );
      await _mediator.executeCommandAsync(command);
      emit(state.copyWith(status: ProductSoftDeleteStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: ProductSoftDeleteStatus.error,
          errorMessage: 'Không thể xóa sản phẩm.',
        ),
      );
    }
  }

  Future<void> restoreProduct({
    required String productId,
    int? expectedVersion,
    String? reason,
  }) async {
    emit(state.copyWith(status: ProductSoftDeleteStatus.restoring));
    try {
      final command = RestoreProductCommand(
        tenantId: await _executionContext.requireTenantId(),
        actorId: await _executionContext.requireUserId(),
        productId: productId,
        expectedVersion: expectedVersion,
        reason: reason,
      );
      await _mediator.executeCommandAsync(command);
      emit(state.copyWith(status: ProductSoftDeleteStatus.restored));
    } on DuplicateSkuException {
      emit(
        state.copyWith(
          status: ProductSoftDeleteStatus.error,
          errorMessage: 'SKU đã được sử dụng bởi sản phẩm khác.',
        ),
      );
    } on DuplicateBarcodeException {
      emit(
        state.copyWith(
          status: ProductSoftDeleteStatus.error,
          errorMessage: 'Mã vạch đã được sử dụng bởi sản phẩm khác.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ProductSoftDeleteStatus.error,
          errorMessage: 'Không thể khôi phục sản phẩm.',
        ),
      );
    }
  }
}
