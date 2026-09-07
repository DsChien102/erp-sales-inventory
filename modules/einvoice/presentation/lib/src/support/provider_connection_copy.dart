import 'package:vet45_einvoice_domain/domain.dart';

import 'einvoice_configuration_display.dart';

abstract final class ProviderConnectionCopy {
  static const pageTitle = 'Kết nối MISA';
  static const sectionTitle = 'Thông tin kết nối';
  static const providerLabel = 'Nhà cung cấp';
  static const taxCodeLabel = 'Mã số thuế đơn vị phát hành';
  static const taxCodeShortLabel = 'MST đơn vị phát hành';
  static const accountLabel = 'Tài khoản MISA';
  static const passwordLabel = 'Mật khẩu MISA';
  static const accountHint = 'Nhập tài khoản MISA';
  static const passwordHint = 'Nhập mật khẩu MISA';
  static const taxCodeCaption = 'Mã số thuế được lấy từ Hồ sơ pháp lý của Tổ chức.';
  static const passwordCaption = 'Mật khẩu được bảo mật và không hiển thị lại sau khi kết nối.';
  static const cancelLabel = 'Hủy';
  static const connectLabel = 'Kết nối';
  static const reconnectSubmitLabel = 'Kết nối lại';
  static const disconnectLabel = 'Ngắt kết nối';
  static const statusLabel = 'Trạng thái';
  static const accountInfoLabel = 'Tài khoản';
  static const statusConnected = 'Đã kết nối';
  static const statusPending = 'Chờ kết nối';
  static const statusError = 'Lỗi kết nối';
  static const pendingBannerTitle = 'Đang chờ kết nối';
  static const pendingBannerDescription =
      'Hệ thống đang tự động hoàn tất kết nối với MISA meInvoice.';
  static const refreshStatusLabel = 'Tải lại trạng thái';
  static const pendingSubmitTitle = 'Đang kiểm tra kết nối';
  static const pendingSubmitMessage =
      'Thông tin đã được lưu an toàn. Hãy đợi worker xử lý rồi tải lại trạng thái.';
  static const errorBannerTitle = 'Không thể kết nối với MISA meInvoice';
  static const errorBannerDescription =
      'Hãy kết nối lại để hệ thống thử lại bằng thông tin hiện có.';
  static const accountRequired = 'Vui lòng nhập tài khoản MISA';
  static const passwordRequired = 'Vui lòng nhập mật khẩu MISA';
  static const connectSuccessTitle = 'Đã kết nối MISA';
  static const connectSuccessMessage = 'Kết nối MISA meInvoice thành công.';
  static const reconnectSuccessTitle = 'Đã kết nối lại';
  static const reconnectSuccessMessage = 'Tài khoản kết nối MISA đã được cập nhật.';
  static const disconnectSuccessTitle = 'Đã ngắt kết nối';
  static const disconnectSuccessMessage =
      'Không thể phát hành hóa đơn điện tử mới cho đến khi kết nối lại.';
  static const recheckSuccessTitle = 'Kết nối hợp lệ';
  static const recheckSuccessMessage = 'Đã xác minh trạng thái kết nối hiện tại.';
  static const authFailedTitle = 'Không kết nối được';
  static const authFailedMessage = 'Tài khoản hoặc mật khẩu không đúng. Hãy kiểm tra lại.';
  static const unavailableTitle = 'Không kiểm tra được';
  static const unavailableMessage = 'Nhà cung cấp tạm thời không phản hồi. Hãy thử lại sau.';
  static const genericErrorTitle = 'Không thực hiện được';
  static const genericErrorMessage = 'Có lỗi xảy ra, vui lòng thử lại.';

  static String statusValue(ProviderConnectionStatus status) {
    return switch (status) {
      ProviderConnectionStatus.connected => statusConnected,
      ProviderConnectionStatus.checkRequired => statusPending,
      ProviderConnectionStatus.reconnectRequired => statusError,
      ProviderConnectionStatus.disconnected => 'Chưa kết nối',
    };
  }

  static const providerValue = EInvoiceConfigurationDisplay.providerName;
  static String maskAccount(String account) {
    final value = account.trim();
    final at = value.indexOf('@');
    if (at > 1) {
      return '${value.substring(0, 2)}***${value.substring(at)}';
    }
    if (value.length > 2) {
      return '${value.substring(0, 2)}***';
    }
    return '***';
  }
}
