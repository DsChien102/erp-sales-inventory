/// Copy strings for SG-02 Order E-Invoice surfaces.
abstract final class OrderEInvoiceCopy {
  static const rowTitle = 'Hóa đơn điện tử';
  static const sheetTitle = 'Hóa đơn điện tử';

  // Row helper (buyer/order readiness) — independent from issuance badge
  static const rowHelperNotReady = 'Chưa đủ thông tin';
  static const rowHelperManage = 'Quản lý HĐĐT';

  // Row badge (issuance lifecycle)
  static const badgeNotIssued = 'Chưa phát hành';
  static const badgeProcessing = 'Đang xử lý';
  static const badgeIssued = 'Đã phát hành';
  static const badgeIssueFailed = 'Phát hành lỗi';

  // Pre-issue actions
  static const issueTitle = 'Phát hành hóa đơn điện tử';
  static const issueSupporting = 'Gửi phát hành qua MISA';
  static const issueDisabledSupporting = 'Cần bổ sung đủ thông tin';

  static const previewTitle = 'Kiểm tra & xem trước';
  static const previewSupporting = 'Kiểm tra và mở bản xem trước từ MISA';

  static const sendTitle = 'Gửi hóa đơn';
  static const sendSupporting = 'Gửi qua email';

  // Post-issue actions
  static const viewOfficialTitle = 'Xem hóa đơn điện tử';
  static const viewOfficialSupporting = 'Mở hóa đơn chính thức từ MISA';

  static const documentsTitle = 'Tài liệu XML & PDF';
  static const documentsSupporting = 'Lưu bản PDF hoặc tệp XML';

  // Delivery badges
  static const deliveryNotSent = 'Chưa gửi';
  static const deliverySending = 'Đang gửi';
  static const deliverySent = 'Đã gửi';
  static const deliverySendFailed = 'Gửi lỗi';

  // Buyer not ready
  static const buyerWarningTitle = 'Chưa đủ thông tin để phát hành';
  static const buyerWarningDescription =
      'Khách hàng còn thiếu thông tin bắt buộc để phát hành hóa đơn.';
  static const buyerCorrectionAction = 'Cập nhật thông tin khách hàng';

  // Blocker results
  static const blockerPageTitle = 'Điều kiện hóa đơn điện tử';

  static const configBlockerTitle = 'Chưa thể tiếp tục';
  static const configBlockerDescription =
      'Hoàn tất kết nối MISA và cấu hình phát hành hóa đơn điện tử trước khi tiếp tục.';
  static const configBlockerAction = 'Mở thiết lập';

  static const orderBlockerTitle = 'Chưa đủ thông tin phát hành';
  static const orderBlockerDescription =
      'Khách hàng còn thiếu thông tin bắt buộc. Cập nhật hồ sơ để tiếp tục.';
  static const orderBlockerAction = 'Cập nhật hồ sơ';

  // Toast
  static const previewFailureMessage =
      'Không thể tạo bản xem trước. Vui lòng thử lại.';

  // SG-03 — issue confirmation + outcome toasts
  static const issueConfirmationTitle = 'Phát hành hóa đơn điện tử?';
  static const issueConfirmationConfirm = 'Phát hành hóa đơn điện tử';
  static const issueConfirmationCancel = 'Hủy';

  static const issueSuccessMessage =
      'Phát hành hóa đơn điện tử thành công.';
  static const issueFailureMessage =
      'Phát hành hóa đơn điện tử không thành công.';

  static String issueConfirmationSummaryLine1({
    required String orderReference,
    required String orderTotal,
  }) =>
      'Đơn hàng $orderReference · Tổng tiền $orderTotal';

  static String issueConfirmationSummaryLine2({
    required String templateNumber,
    required String templateSymbol,
    required String authorityMode,
  }) =>
      'Mẫu $templateNumber · Ký hiệu $templateSymbol · $authorityMode';
}
