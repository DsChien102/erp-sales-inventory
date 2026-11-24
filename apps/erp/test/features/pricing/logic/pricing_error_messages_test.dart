import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/pricing/data/pricing_errors.dart';
import 'package:erp/features/pricing/logic/pricing_error_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const expectedMessages = <String, String>{
    PricingErrorCodes.noPermission:
        'Bạn không có quyền thực hiện thao tác này.',
    PricingErrorCodes.validationError: 'Thông tin nhập không hợp lệ.',
    PricingErrorCodes.referenceInvalid:
        'Khách hàng hoặc sản phẩm không hợp lệ.',
    PricingErrorCodes.belowFloorBlocked: 'Giá nhập thấp hơn giá sàn quy định.',
    PricingErrorCodes.duplicateActiveRule:
        'Đã có giá riêng khác đang áp dụng cho cùng khách hàng và sản phẩm.',
    PricingErrorCodes.stateChanged: 'Dữ liệu đã thay đổi. Vui lòng tải lại.',
    PricingErrorCodes.invalidStatus:
        'Không thể thực hiện với trạng thái hiện tại.',
    PricingErrorCodes.notFound: 'Mức giá riêng không còn tồn tại.',
    PricingErrorCodes.idempotencyConflict:
        'Không thể lưu giá riêng. Vui lòng thử lại.',
    PricingErrorCodes.systemError: 'Đã xảy ra lỗi. Vui lòng thử lại.',
  };

  for (final entry in expectedMessages.entries) {
    test('maps ${entry.key} to TH-04 6.4 message', () {
      final msg = pricingErrorMessage(
        AppException(entry.key, serverMessage: 'raw server text'),
        fallback: 'Fallback',
      );
      expect(msg, entry.value);
      expect(msg, isNot(contains(entry.key)));
      expect(msg, isNot(contains('raw server text')));
    });
  }

  test('returns fallback for unknown code and never leaks serverMessage', () {
    final msg = pricingErrorMessage(
      const AppException('X_CODE', serverMessage: 'raw'),
      fallback: 'F',
    );
    expect(msg, 'F');
  });

  test('maps non-AppException (e.g. StateError) to SYSTEM_ERROR message', () {
    final msg = pricingErrorMessage(
      StateError('internal crash'),
      fallback: 'F',
    );
    expect(msg, 'Đã xảy ra lỗi. Vui lòng thử lại.');
  });

  test('prioritizes overrides over default table', () {
    final msg = pricingErrorMessage(
      const AppException(PricingErrorCodes.stateChanged),
      fallback: 'F',
      overrides: const {'STATE_CHANGED': 'A'},
    );
    expect(msg, 'A');
  });
}

