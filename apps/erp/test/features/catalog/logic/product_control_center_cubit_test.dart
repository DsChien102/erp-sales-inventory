import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/catalog/logic/product_control_center_cubit.dart';
import 'package:erp/features/catalog/logic/product_control_center_state.dart';
import 'package:flutter_test/flutter_test.dart';

final class _DelayedProductRepository extends Fake implements ProductRepository {
  final queryCompleter = Completer<ProductControlCenterDto>();
  final commandCompleter = Completer<void>();

  @override
  Future<ProductControlCenterDto> getControlCenter(String productId) async {
    return await queryCompleter.future;
  }

  @override
  Future<void> deactivate({
    required String productId,
    int? expectedVersion,
    String? reason,
    bool confirmAcknowledgeWarnings = false,
  }) async {
    return await commandCompleter.future;
  }
}

final class _MockProductRepository extends Fake implements ProductRepository {
  _MockProductRepository({
    this.onGetControlCenter,
    this.onDeactivate,
  });

  final Future<ProductControlCenterDto> Function(String productId)? onGetControlCenter;
  final Future<void> Function({
    required String productId,
    int? expectedVersion,
    String? reason,
    bool confirmAcknowledgeWarnings,
  })? onDeactivate;

  @override
  Future<ProductControlCenterDto> getControlCenter(String productId) async {
    if (onGetControlCenter != null) {
      return onGetControlCenter!(productId);
    }
    throw UnimplementedError();
  }

  @override
  Future<void> deactivate({
    required String productId,
    int? expectedVersion,
    String? reason,
    bool confirmAcknowledgeWarnings = false,
  }) async {
    if (onDeactivate != null) {
      return onDeactivate!(
        productId: productId,
        expectedVersion: expectedVersion,
        reason: reason,
        confirmAcknowledgeWarnings: confirmAcknowledgeWarnings,
      );
    }
    throw UnimplementedError();
  }
}

void main() {
  group('ProductControlCenterCubit (H3)', () {
    ProductControlCenterCubit buildCubit(ProductRepository repo) {
      return ProductControlCenterCubit(
        productRepository: repo,
      );
    }

    test('ignores a failed control-center query after the cubit is closed', () async {
      final repo = _DelayedProductRepository();
      final cubit = buildCubit(repo);

      final load = cubit.loadControlCenter('product-1');
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
      repo.queryCompleter.completeError(StateError('RPC failed'));

      await expectLater(load, completes);
    });

    test('ignores a failed lifecycle command after the cubit is closed', () async {
      final repo = _DelayedProductRepository();
      final cubit = buildCubit(repo);

      final deactivate = cubit.deactivateProduct('product-1');
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
      repo.commandCompleter.completeError(StateError('RPC failed'));

      await expectLater(deactivate, completes);
    });

    test('emits warning state with 2 warnings on BUSINESS_STATUS_WARNINGS_REQUIRE_ACK', () async {
      final repo = _MockProductRepository(
        onDeactivate: ({
          required String productId,
          int? expectedVersion,
          String? reason,
          bool confirmAcknowledgeWarnings = false,
        }) async {
          throw const AppException(
            CatalogErrorCodes.statusWarningsRequireAck,
            details: {
              'warnings': [
                {'code': 'HAS_STOCK', 'message': 'Sản phẩm còn tồn kho.'},
                {'code': 'OPEN_ORDERS', 'message': 'Sản phẩm có đơn hàng đang xử lý.'},
              ],
            },
          );
        },
      );
      final cubit = buildCubit(repo);

      await cubit.deactivateProduct('product-1');

      expect(cubit.state.actionStatus, ProductLifecycleActionStatus.warning);
      expect(cubit.state.actionWarnings, isNotNull);
      final warnings = cubit.state.actionWarnings!;
      expect(warnings.length, 2);
      expect(warnings[0].code, 'HAS_STOCK');
      expect(warnings[0].message, 'Sản phẩm còn tồn kho.');
      expect(warnings[1].code, 'OPEN_ORDERS');
      expect(warnings[1].message, 'Sản phẩm có đơn hàng đang xử lý.');
    });

    test('emits stale product version message on STALE_PRODUCT_VERSION', () async {
      final repo = _MockProductRepository(
        onDeactivate: ({
          required String productId,
          int? expectedVersion,
          String? reason,
          bool confirmAcknowledgeWarnings = false,
        }) async {
          throw const AppException(
            CatalogErrorCodes.staleProductVersion,
          );
        },
      );
      final cubit = buildCubit(repo);

      await cubit.deactivateProduct('product-1');

      expect(cubit.state.actionStatus, ProductLifecycleActionStatus.failure);
      expect(cubit.state.actionErrorMessage, 'Sản phẩm đã được cập nhật ở nơi khác. Vui lòng tải lại.');
    });

    test('emits product not found message on PRODUCT_NOT_FOUND', () async {
      final repo = _MockProductRepository(
        onGetControlCenter: (productId) async {
          throw const AppException(
            CatalogErrorCodes.productNotFound,
          );
        },
      );
      final cubit = buildCubit(repo);

      await cubit.loadControlCenter('product-unknown');

      expect(cubit.state.status, ProductControlCenterStatus.failure);
      expect(cubit.state.errorMessage, 'Sản phẩm không tồn tại hoặc đã bị xoá.');
    });
  });
}
