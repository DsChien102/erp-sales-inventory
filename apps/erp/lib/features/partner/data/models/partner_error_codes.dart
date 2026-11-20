import 'package:erp/core/errors/app_exception.dart';

/// Mã lỗi partner (`CODE: …` từ `partner._raise_partner_error`). Cùng giá trị chuỗi với
/// `PartnerBlockedCodes` của module cũ.
abstract final class PartnerErrorCodes {
  static const noPermission = AppErrorCode.noPermission;
  static const notFound = AppErrorCode.notFound;
  static const validationError = AppErrorCode.validation;
  static const stateChanged = AppErrorCode.stateChanged;
  static const systemError = AppErrorCode.unknown;
  static const duplicateWarning = 'DUPLICATE_WARNING';
  static const invalidStatus = 'INVALID_STATUS';
  static const systemLocked = 'PARTNER_SYSTEM_LOCKED';
  static const hasTransactions = 'HAS_TRANSACTIONS';
  static const primaryContactOfOrganization = 'PRIMARY_CONTACT_OF_ORGANIZATION';
}
