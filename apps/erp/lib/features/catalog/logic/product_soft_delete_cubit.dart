import 'package:erp/core/errors/app_exception.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/catalog_errors.dart';
import '../data/product_repository.dart';
import 'product_soft_delete_state.dart';

class ProductSoftDeleteCubit extends Cubit<ProductSoftDeleteState> {
  ProductSoftDeleteCubit({
    required ProductRepository productRepository,
  })  : _productRepository = productRepository,
        super(const ProductSoftDeleteState());

  final ProductRepository _productRepository;

  Future<void> checkEligibility(String productId) async {
    emit(state.copyWith(status: ProductSoftDeleteStatus.checkingEligibility));
    try {
      final result = await _productRepository.checkDeletionEligibility(productId);
      emit(
        state.copyWith(
          status: ProductSoftDeleteStatus.eligibilityChecked,
          eligibility: result,
        ),
      );
    } catch (_) {
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
      await _productRepository.delete(
        productId: productId,
        confirmAcknowledgeWarnings: confirmAcknowledgeWarnings,
        expectedVersion: expectedVersion,
      );
      emit(state.copyWith(status: ProductSoftDeleteStatus.success));
    } catch (_) {
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
      await _productRepository.restore(
        productId: productId,
        expectedVersion: expectedVersion,
        reason: reason,
      );
      emit(state.copyWith(status: ProductSoftDeleteStatus.restored));
    } on AppException catch (e) {
      if (e.code == CatalogErrorCodes.duplicateSku) {
        emit(
          state.copyWith(
            status: ProductSoftDeleteStatus.error,
            errorMessage: 'SKU đã được sử dụng bởi sản phẩm khác.',
          ),
        );
        return;
      }
      if (e.code == CatalogErrorCodes.duplicateBarcode) {
        emit(
          state.copyWith(
            status: ProductSoftDeleteStatus.error,
            errorMessage: 'Mã vạch đã được sử dụng bởi sản phẩm khác.',
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: ProductSoftDeleteStatus.error,
          errorMessage: 'Không thể khôi phục sản phẩm.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProductSoftDeleteStatus.error,
          errorMessage: 'Không thể khôi phục sản phẩm.',
        ),
      );
    }
  }
}
