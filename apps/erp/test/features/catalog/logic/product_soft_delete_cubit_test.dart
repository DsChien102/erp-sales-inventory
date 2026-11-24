import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/catalog/logic/product_soft_delete_cubit.dart';
import 'package:erp/features/catalog/logic/product_soft_delete_state.dart';
import 'package:flutter_test/flutter_test.dart';

final class _MockProductRepository extends Fake implements ProductRepository {
  _MockProductRepository({
    this.onCheckDeletionEligibility,
    this.onDelete,
    this.onRestore,
  });

  final Future<ProductDeletionEligibilityDto> Function(String productId)? onCheckDeletionEligibility;
  final Future<void> Function({
    required String productId,
    int? expectedVersion,
    String? reason,
    bool confirmAcknowledgeWarnings,
  })? onDelete;
  final Future<void> Function({
    required String productId,
    int? expectedVersion,
    String? reason,
  })? onRestore;

  @override
  Future<ProductDeletionEligibilityDto> checkDeletionEligibility(String productId) {
    if (onCheckDeletionEligibility != null) {
      return onCheckDeletionEligibility!(productId);
    }
    throw UnimplementedError();
  }

  @override
  Future<void> delete({
    required String productId,
    int? expectedVersion,
    String? reason,
    bool confirmAcknowledgeWarnings = false,
  }) {
    if (onDelete != null) {
      return onDelete!(
        productId: productId,
        expectedVersion: expectedVersion,
        reason: reason,
        confirmAcknowledgeWarnings: confirmAcknowledgeWarnings,
      );
    }
    throw UnimplementedError();
  }

  @override
  Future<void> restore({
    required String productId,
    int? expectedVersion,
    String? reason,
  }) {
    if (onRestore != null) {
      return onRestore!(
        productId: productId,
        expectedVersion: expectedVersion,
        reason: reason,
      );
    }
    throw UnimplementedError();
  }
}

void main() {
  group('ProductSoftDeleteCubit (H5 - 5 fixed error messages)', () {
    test('1. checkEligibility error emits fixed message', () async {
      final repo = _MockProductRepository(
        onCheckDeletionEligibility: (id) async => throw Exception('RPC failed'),
      );
      final cubit = ProductSoftDeleteCubit(productRepository: repo);

      await cubit.checkEligibility('prod-1');

      expect(cubit.state.status, ProductSoftDeleteStatus.error);
      expect(cubit.state.errorMessage, 'Không thể kiểm tra điều kiện xóa sản phẩm.');
    });

    test('2. deleteProduct error emits fixed message', () async {
      final repo = _MockProductRepository(
        onDelete: ({required productId, confirmAcknowledgeWarnings = false, expectedVersion, reason}) async =>
            throw Exception('Delete RPC failed'),
      );
      final cubit = ProductSoftDeleteCubit(productRepository: repo);

      await cubit.deleteProduct(
        productId: 'prod-1',
        confirmAcknowledgeWarnings: true,
      );

      expect(cubit.state.status, ProductSoftDeleteStatus.error);
      expect(cubit.state.errorMessage, 'Không thể xóa sản phẩm.');
    });

    test('3. restoreProduct DUPLICATE_SKU emits fixed message', () async {
      final repo = _MockProductRepository(
        onRestore: ({required productId, expectedVersion, reason}) async =>
            throw const AppException(CatalogErrorCodes.duplicateSku),
      );
      final cubit = ProductSoftDeleteCubit(productRepository: repo);

      await cubit.restoreProduct(productId: 'prod-1');

      expect(cubit.state.status, ProductSoftDeleteStatus.error);
      expect(cubit.state.errorMessage, 'SKU đã được sử dụng bởi sản phẩm khác.');
    });

    test('4. restoreProduct DUPLICATE_BARCODE emits fixed message', () async {
      final repo = _MockProductRepository(
        onRestore: ({required productId, expectedVersion, reason}) async =>
            throw const AppException(CatalogErrorCodes.duplicateBarcode),
      );
      final cubit = ProductSoftDeleteCubit(productRepository: repo);

      await cubit.restoreProduct(productId: 'prod-1');

      expect(cubit.state.status, ProductSoftDeleteStatus.error);
      expect(cubit.state.errorMessage, 'Mã vạch đã được sử dụng bởi sản phẩm khác.');
    });

    test('5. restoreProduct other error emits fixed message', () async {
      final repo = _MockProductRepository(
        onRestore: ({required productId, expectedVersion, reason}) async =>
            throw const AppException(AppErrorCode.unknown, serverMessage: 'Other failure'),
      );
      final cubit = ProductSoftDeleteCubit(productRepository: repo);

      await cubit.restoreProduct(productId: 'prod-1');

      expect(cubit.state.status, ProductSoftDeleteStatus.error);
      expect(cubit.state.errorMessage, 'Không thể khôi phục sản phẩm.');
    });
  });
}
