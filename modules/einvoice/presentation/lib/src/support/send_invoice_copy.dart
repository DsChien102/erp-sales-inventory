/// Copy strings for SG-07 send / resend / delivery history surfaces.
abstract final class SendInvoiceCopy {
  static const sendTitle = 'Gửi hóa đơn điện tử';
  static const resendTitle = 'Gửi lại hóa đơn điện tử';

  static const recipientLabel = 'Email người nhận';
  static const recipientPlaceholder = 'Nhập email';
  static const recipientHelper = 'Email chỉ áp dụng cho lần gửi này.';
  static const recipientInvalid = 'Email không đúng định dạng.';

  static const sendAction = 'Gửi hóa đơn';
  static const resendAction = 'Gửi lại hóa đơn';
  static const cancelAction = 'Hủy';
  static const viewHistoryLink = 'Xem lịch sử gửi';

  static const historyPageTitle = 'Lịch sử gửi hóa đơn';
  static const historySectionTitle = 'Các lần gửi';
  static const issuedBadge = 'Đã phát hành';
  static const actorAutomatic = 'Tự động';

  static const deliverySuccessPrefix = 'Đã gửi';
  static const deliveryFailedPrefix = 'Gửi lỗi';

  static const sendSuccessMessage = 'Đã gửi hóa đơn.';
  static const sendFailureMessage =
      'Không thể gửi hóa đơn. Vui lòng thử lại.';

  static String invoiceIdentity({
    required String invoiceNumber,
    required String invoiceSymbol,
  }) =>
      'Hóa đơn số $invoiceNumber · Ký hiệu $invoiceSymbol';

  static String latestDeliverySummary({
    required String email,
    required String dateTime,
  }) =>
      'Đã gửi gần nhất đến $email · $dateTime';

  static String invoiceSummaryTitle(String invoiceNumber) =>
      'Hóa đơn số $invoiceNumber';

  static String invoiceMetadata({
    required String templateNumber,
    required String invoiceSymbol,
  }) =>
      'Mẫu $templateNumber · Ký hiệu $invoiceSymbol';

  static String issuedAt({
    required String issuedTime,
    required String issuedDate,
  }) =>
      'Phát hành lúc $issuedTime, $issuedDate';

  static String deliveryMainText({
    required bool success,
    required String email,
  }) {
    final prefix =
        success ? deliverySuccessPrefix : deliveryFailedPrefix;
    return '$prefix · $email';
  }

  static String deliveryMetadata({
    required String date,
    required String time,
    required String actor,
  }) =>
      '$date · $time · $actor';

  /// Lightweight email format check for sheet validation (presentation only).
  static bool isValidEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
  }
}
