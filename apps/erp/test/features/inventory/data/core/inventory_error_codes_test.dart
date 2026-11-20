import 'package:flutter_test/flutter_test.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';

void main() {
  group('InventoryErrorCode', () {
    test('maps_core_14_codes', () {
      final codes = [
        InventoryErrorCode.permissionDenied,
        InventoryErrorCode.contextInvalid,
        InventoryErrorCode.dataScopeDenied,
        InventoryErrorCode.idempotencyConflict,
        InventoryErrorCode.commandInProgress,
        InventoryErrorCode.versionConflict,
        InventoryErrorCode.insufficientStock,
        InventoryErrorCode.lotRequired,
        InventoryErrorCode.lotNotAllowed,
        InventoryErrorCode.expiryRequired,
        InventoryErrorCode.lotAttributeConflict,
        InventoryErrorCode.trackingLocked,
        InventoryErrorCode.unitCostRequired,
        InventoryErrorCode.periodClosed,
      ];

      expect(codes.length, 14);
      expect(InventoryErrorCode.permissionDenied, AppErrorCode.noPermission);

      for (final code in codes) {
        final msg = inventoryErrorMessage(
          AppException(code),
          fallback: 'fallback',
        );
        expect(msg, isNotEmpty);
        expect(msg, isNot(equals('fallback')));
      }
    });

    test('overrides_take_precedence', () {
      final msg = inventoryErrorMessage(
        const AppException(InventoryErrorCode.insufficientStock),
        fallback: 'fallback',
        overrides: {
          InventoryErrorCode.insufficientStock: 'Kho đã hết mặt hàng này rồi.',
        },
      );
      expect(msg, 'Kho đã hết mặt hàng này rồi.');
    });

    test('fallback_when_unknown', () {
      final msg = inventoryErrorMessage(
        const AppException('SOME_RANDOM_CODE'),
        fallback: 'Đã có lỗi xảy ra',
      );
      expect(msg, 'Đã có lỗi xảy ra');
    });
  });
}
