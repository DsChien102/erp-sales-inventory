import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/catalog_errors.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/catalog/logic/product_stock_adjustment_cubit.dart';
import 'package:erp/features/catalog/logic/product_stock_adjustment_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingProductRepository extends Fake implements ProductRepository {
  final List<String> calls = [];
  String? lastSetProductId;
  int? lastSetQuantity;
  String? lastAdjustProductId;
  int? lastAdjustNewQuantity;
  String? lastAdjustReason;
  int? lastAdjustExpectedQuantity;
  Object? errorToThrow;
  Completer<void>? pendingCompleter;

  @override
  Future<void> setBasicStock({required String productId, required int quantity}) async {
    calls.add('setBasicStock');
    lastSetProductId = productId;
    lastSetQuantity = quantity;
    if (pendingCompleter != null) await pendingCompleter!.future;
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<void> adjustBasicStock({
    required String productId,
    required int newQuantity,
    String? reason,
    int? expectedQuantity,
  }) async {
    calls.add('adjustBasicStock');
    lastAdjustProductId = productId;
    lastAdjustNewQuantity = newQuantity;
    lastAdjustReason = reason;
    lastAdjustExpectedQuantity = expectedQuantity;
    if (pendingCompleter != null) await pendingCompleter!.future;
    if (errorToThrow != null) throw errorToThrow!;
  }
}

void main() {
  group('combineStockAdjustmentReason', () {
    test('combines chip and trimmed note', () {
      expect(
        combineStockAdjustmentReason(chip: 'Hao hụt', note: ' vỡ 3 chai '),
        'Hao hụt - vỡ 3 chai',
      );
    });

    test('returns note only when chip is null', () {
      expect(combineStockAdjustmentReason(chip: null, note: 'x'), 'x');
    });

    test('returns chip only when note is empty', () {
      expect(combineStockAdjustmentReason(chip: 'Khác', note: ''), 'Khác');
    });

    test('returns null when both are empty or whitespace', () {
      expect(combineStockAdjustmentReason(chip: null, note: '   '), isNull);
    });
  });

  group('ProductStockAdjustmentCubit', () {
    late _RecordingProductRepository repository;
    late ProductStockAdjustmentCubit cubit;

    setUp(() {
      repository = _RecordingProductRepository();
      cubit = ProductStockAdjustmentCubit(productRepository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('submit initial calls setBasicStock only and ignores chip/note', () async {
      await cubit.submit(
        productId: 'p-1',
        quantity: 30,
        currentQuantity: null,
        chip: 'Khác',
        note: 'note',
      );

      expect(repository.calls, ['setBasicStock']);
      expect(repository.lastSetProductId, 'p-1');
      expect(repository.lastSetQuantity, 30);
      expect(cubit.state.status, ProductStockAdjustmentStatus.success);
    });

    test('submit adjust passes expected = currentQuantity and combined reason', () async {
      await cubit.submit(
        productId: 'p-1',
        quantity: 47,
        currentQuantity: 50,
        chip: 'Hao hụt',
        note: 'vỡ 3 chai',
      );

      expect(repository.calls, ['adjustBasicStock']);
      expect(repository.lastAdjustProductId, 'p-1');
      expect(repository.lastAdjustNewQuantity, 47);
      expect(repository.lastAdjustExpectedQuantity, 50);
      expect(repository.lastAdjustReason, 'Hao hụt - vỡ 3 chai');
      expect(cubit.state.status, ProductStockAdjustmentStatus.success);
    });

    test('emits [loading, success]', () async {
      final expectation = expectLater(
        cubit.stream.map((s) => s.status),
        emitsInOrder([ProductStockAdjustmentStatus.loading, ProductStockAdjustmentStatus.success]),
      );

      await cubit.submit(productId: 'p-1', quantity: 10, currentQuantity: null);
      await expectation;
    });

    test('failure maps STALE_STOCK_QUANTITY to 6.4 text', () async {
      repository.errorToThrow = const AppException(CatalogErrorCodes.staleStockQuantity);

      await cubit.submit(productId: 'p-1', quantity: 10, currentQuantity: 5);

      expect(cubit.state.status, ProductStockAdjustmentStatus.failure);
      expect(
        cubit.state.errorMessage,
        'Tồn kho hiện tại đã thay đổi. Vui lòng tải lại dữ liệu trước khi điều chỉnh.',
      );
    });
  });
}
