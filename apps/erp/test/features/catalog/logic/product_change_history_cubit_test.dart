import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/catalog/logic/product_change_history_cubit.dart';
import 'package:erp/features/catalog/logic/product_change_history_state.dart';
import 'package:flutter_test/flutter_test.dart';

final class _MockProductRepository extends Fake implements ProductRepository {
  _MockProductRepository({required this.onGetChangeHistory});

  final Future<ProductChangeHistoryResultDto> Function({
    required String productId,
    List<String>? changeCategories,
    int limit,
    int offset,
  }) onGetChangeHistory;

  @override
  Future<ProductChangeHistoryResultDto> getChangeHistory({
    required String productId,
    List<String>? changeCategories,
    int limit = 50,
    int offset = 0,
  }) {
    return onGetChangeHistory(
      productId: productId,
      changeCategories: changeCategories,
      limit: limit,
      offset: offset,
    );
  }
}

void main() {
  group('ProductChangeHistoryCubit (H4)', () {
    test('fetches page 1 and page 2, appending items and updating hasReachedMax', () async {
      int callCount = 0;
      final dummyEntry = ProductChangeHistoryEntryDto(
        id: 'history-1',
        changeType: ProductChangeHistoryAction.profileUpdated,
        summary: 'Cập nhật tên sản phẩm',
        actorDisplayName: 'Admin',
        occurredAt: DateTime.utc(2026, 11, 3),
      );

      final repo = _MockProductRepository(
        onGetChangeHistory: ({
          required String productId,
          List<String>? changeCategories,
          int limit = 20,
          int offset = 0,
        }) async {
          callCount++;
          if (offset == 0) {
            return ProductChangeHistoryResultDto(
              productId: productId,
              items: List.generate(20, (i) => dummyEntry),
              totalCount: 25,
            );
          } else {
            return ProductChangeHistoryResultDto(
              productId: productId,
              items: List.generate(5, (i) => dummyEntry),
              totalCount: 25,
            );
          }
        },
      );

      final cubit = ProductChangeHistoryCubit(productRepository: repo);

      // Page 1
      await cubit.loadHistory('prod-1');
      expect(cubit.state.status, ProductChangeHistoryStatus.success);
      expect(cubit.state.items.length, 20);
      expect(cubit.state.hasReachedMax, isFalse);
      expect(cubit.state.offset, 20);

      // Page 2
      await cubit.loadHistory('prod-1');
      expect(cubit.state.status, ProductChangeHistoryStatus.success);
      expect(cubit.state.items.length, 25);
      expect(cubit.state.hasReachedMax, isTrue);
      expect(callCount, 2);
    });

    test('emits failure with catalog error message on exception', () async {
      final repo = _MockProductRepository(
        onGetChangeHistory: ({
          required String productId,
          List<String>? changeCategories,
          int limit = 20,
          int offset = 0,
        }) async {
          throw const AppException(
            AppErrorCode.noPermission,
            serverMessage: 'Permission denied to view history',
          );
        },
      );

      final cubit = ProductChangeHistoryCubit(productRepository: repo);

      await cubit.loadHistory('prod-1');

      expect(cubit.state.status, ProductChangeHistoryStatus.failure);
      expect(cubit.state.errorMessage, 'Bạn không có quyền thực hiện thao tác này.');
    });
  });
}
