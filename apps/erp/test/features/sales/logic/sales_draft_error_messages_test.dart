import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/logic/sales_draft_error_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const table = {
    'NO_PERMISSION': 'Bạn không có quyền thực hiện thao tác này.',
    'DATA_SCOPE_DENIED': 'Cửa hàng hiện tại không còn khả dụng.',
    'STALE_DATA': 'Đơn nháp này đã bị xoá hoặc thay đổi ở nơi khác.',
    'IDEMPOTENCY_CONFLICT': 'Yêu cầu bị xung đột',
  };
  for (final entry in table.entries) {
    test('message_${entry.key}', () {
      expect(salesDraftErrorMessage(AppException(entry.key), fallback: 'F'), entry.value);
    });
  }

  test('fallback_for_other_codes_and_errors', () {
    expect(salesDraftErrorMessage(const AppException('SYSTEM_ERROR'), fallback: 'F'), 'F');
    expect(
      salesDraftErrorMessage(const AppException('X', serverMessage: 'raw'), fallback: 'F'),
      'F',
    );
    expect(salesDraftErrorMessage(StateError('x'), fallback: 'F'), 'F');
  });

  test('overrides_win', () {
    expect(
      salesDraftErrorMessage(
        const AppException('STALE_DATA'),
        fallback: 'F',
        overrides: {'STALE_DATA': 'A'},
      ),
      'A',
    );
  });
}
