import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/logic/sales_checkout_error_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const table = {
    'NO_PERMISSION': 'Bạn không có quyền thực hiện thao tác này.',
    'DATA_SCOPE_DENIED': 'Cửa hàng hiện tại không còn khả dụng.',
    'CONTEXT_INVALID': 'Ngữ cảnh thanh toán không hợp lệ.',
    'IDEMPOTENCY_CONFLICT': 'Yêu cầu bị xung đột',
    'PRODUCT_NOT_SELLABLE': 'Sản phẩm đã ngừng bán. Vui lòng quay lại đơn.',
    'PRICE_CHANGED': 'Giá đã thay đổi. Vui lòng quay lại kiểm tra.',
    'PRICING_BLOCKED': 'Sản phẩm này chưa có giá bán.',
    'CHECKOUT_BLOCKED': 'Đơn chưa đủ điều kiện thanh toán.',
  };
  for (final entry in table.entries) {
    test('${entry.key} → 6.4', () {
      expect(salesCheckoutErrorMessage(AppException(entry.key), fallback: 'F'), entry.value);
    });
  }
  test('override wins', () {
    expect(
      salesCheckoutErrorMessage(
        const AppException('NO_PERMISSION'),
        fallback: 'F',
        overrides: {'NO_PERMISSION': 'A'},
      ),
      'A',
    );
  });
  test('fallback never shows server message', () {
    expect(salesCheckoutErrorMessage(const AppException('SYSTEM_ERROR'), fallback: 'F'), 'F');
    expect(
      salesCheckoutErrorMessage(const AppException('X', serverMessage: 'raw'), fallback: 'F'),
      'F',
    );
    expect(salesCheckoutErrorMessage(StateError('x'), fallback: 'F'), 'F');
  });
}
