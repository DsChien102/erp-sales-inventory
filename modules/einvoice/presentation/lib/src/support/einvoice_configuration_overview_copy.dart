import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

/// Display copy for SG-01 overview (D01/D02). Overlay fields BA/DTO chưa có.
abstract final class EInvoiceConfigurationOverviewCopy {
  static const providerName = 'MISA meInvoice';
  static const connectionDisconnected = 'Chưa kết nối MISA meInvoice';
  static const connectionConnected = 'MISA meInvoice · Đã kết nối';
  static const connectionCheckRequired = 'Cần kiểm tra lại';
  static const connectionReconnectRequired = 'Cần kết nối lại';
  static const issuanceMissing = 'Chưa chọn mẫu hóa đơn mặc định';
  static const automationNotReady = 'Phát hành hóa đơn và gửi email tự động.';
  static const authorityWithTaxCode = 'Có mã của cơ quan thuế';
  static const readyTitle = 'Sẵn sàng phát hành';
  static const readyDescription = 'Đã đủ điều kiện phát hành hóa đơn điện tử từ đơn hàng Hoàn tất.';
  static const notReadyTitle = 'Chưa sẵn sàng phát hành';
  static const notReadyEyebrow = 'Cần hoàn tất';
  static const completeActionLabel = 'Xem và hoàn tất';
  static const connectionTitle = 'Kết nối MISA';
  static const issuanceTitle = 'Cấu hình phát hành';
  static const automationTitle = 'Tự động hóa';

  static String notReadyDescription(int blockerCount) {
    return 'Còn $blockerCount điều kiện cần hoàn tất trước khi có thể phát hành hóa đơn điện tử.';
  }

  static String connectionSubtitle(ProviderConnectionStatus status) {
    return switch (status) {
      ProviderConnectionStatus.disconnected => connectionDisconnected,
      ProviderConnectionStatus.connected => connectionConnected,
      ProviderConnectionStatus.checkRequired => connectionCheckRequired,
      ProviderConnectionStatus.reconnectRequired => connectionReconnectRequired,
    };
  }

  static String issuanceSubtitle({
    required IssuanceProfileDto profile,
    required List<ProviderTemplateDto> templates,
  }) {
    final templateId = profile.templateId;
    if (templateId == null || templateId.isEmpty) {
      return issuanceMissing;
    }
    final match = templates.where((item) => item.templateId == templateId);
    final symbol = match.isEmpty ? null : match.first.symbol;
    if (symbol == null || symbol.isEmpty) {
      return templateId;
    }
    return '$symbol · $authorityWithTaxCode';
  }

  static String automationSubtitle({
    required bool isReady,
    required AutomationPolicyDto policy,
  }) {
    if (!isReady) {
      return automationNotReady;
    }
    final issue = policy.autoIssueEnabled ? 'Phát hành tự động' : 'Phát hành thủ công';
    final send = policy.autoSendEnabled ? 'Gửi email tự động' : 'Gửi email thủ công';
    return '$issue · $send';
  }
}
