import 'package:erp/core/errors/app_exception.dart';

import '../data/models/partner_error_codes.dart';

/// TH-03 mục 6.4. [fallback] là câu "Không thể … Vui lòng thử lại." của thao tác.
String partnerErrorMessage(
  Object error, {
  required String fallback,
  String? noPermission,
}) {
  final code = error is AppException ? error.code : AppErrorCode.unknown;
  return switch (code) {
    PartnerErrorCodes.noPermission =>
      noPermission ?? 'Bạn không có quyền thực hiện thao tác này.',
    PartnerErrorCodes.notFound => 'Không tìm thấy hồ sơ.',
    PartnerErrorCodes.stateChanged =>
      'Hồ sơ đã được cập nhật bởi người khác. Vui lòng tải lại.',
    PartnerErrorCodes.invalidStatus =>
      'Trạng thái hồ sơ không cho phép thao tác này.',
    PartnerErrorCodes.duplicateWarning =>
      'Đã tồn tại hồ sơ trùng MST/SĐT/email. Vui lòng kiểm tra lại.',
    _ => fallback,
  };
}
