import 'package:vet45_einvoice_domain/domain.dart';

/// Copy strings for app-owned SG-07 send / resend sheets.
abstract final class OrderInvoiceDeliveryCopy {
  static const sendTitle = 'Gửi hóa đơn điện tử';
  static const resendTitle = 'Gửi lại hóa đơn điện tử';
  static const recipientLabel = 'Email người nhận';
  static const recipientPlaceholder = 'Nhập email';
  static const recipientHelper = 'Email chỉ áp dụng cho lần gửi này.';
  static const recipientInvalid = 'Email không đúng định dạng.';
  static const sendAction = 'Gửi hóa đơn';
  // Canonical SG07-O02 giữ cùng CTA copy với lần gửi đầu.
  static const resendAction = 'Gửi hóa đơn';
  static const cancelAction = 'Hủy';
  static const viewHistory = 'Xem lịch sử gửi';
  static const historyPageTitle = 'Lịch sử gửi hóa đơn';
  static const historySectionTitle = 'Các lần gửi';
  static const historyEmpty = 'Chưa có lịch sử gửi hóa đơn.';
  static const historyRetry = 'Thử lại';
  static const historyLoadFailed = 'Không thể tải lịch sử gửi hóa đơn.';
  static const operationLocked = 'Yêu cầu gửi trước đang được xử lý. Vui lòng chờ kết quả.';

  static String latestDeliverySummary({
    required String email,
    required String dateTime,
  }) => 'Đã gửi gần nhất đến $email · $dateTime';

  static String? suggestionSource(DeliveryRecipientSource? source) => switch (source) {
    DeliveryRecipientSource.currentPartnerProfile => 'Hồ sơ khách hàng',
    DeliveryRecipientSource.lastSuccessfulPartnerDelivery =>
      'Email đã dùng gần nhất cho khách hàng này',
    DeliveryRecipientSource.buyerInvoiceSnapshot => 'Thông tin người mua trên hóa đơn',
    DeliveryRecipientSource.lastInvoiceDelivery => 'Lần gửi gần nhất của hóa đơn này',
    DeliveryRecipientSource.userInput || null => null,
  };

  static bool isValidEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
  }
}
