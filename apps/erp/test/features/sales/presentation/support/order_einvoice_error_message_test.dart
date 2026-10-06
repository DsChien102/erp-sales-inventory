import 'package:erp/features/sales/presentation/support/order_einvoice_error_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_einvoice_application/application.dart';

void main() {
  test('missing invoice template says to choose a template', () {
    expect(
      OrderEInvoiceErrorMessage.of(
        const EInvoiceBlockedException(EInvoiceBlockedCodes.configNotReady),
      ),
      'Chưa chọn mẫu hóa đơn. Vui lòng cập nhật cấu hình phát hành.',
    );
  });

  test('fully returned order has its own message', () {
    expect(
      OrderEInvoiceErrorMessage.of(
        'ISSUANCE_NOT_READY: {"details": {"blockers": ["ORDER_FULLY_RETURNED"]}}',
      ),
      'Đơn hàng đã trả hết hàng, không cần xuất hóa đơn.',
    );
  });

  test('source version mismatch asks to reload', () {
    expect(
      OrderEInvoiceErrorMessage.of(
        'ISSUANCE_NOT_READY: {"details": {"blockers": ["SOURCE_VERSION_MISMATCH"]}}',
      ),
      'Đơn hàng vừa thay đổi (đổi/trả). Vui lòng tải lại rồi phát hành.',
    );
  });
}
