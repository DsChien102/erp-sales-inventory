import 'package:erp/core/errors/app_exception.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'iam_ui_failure.dart';

/// Maps application/IAM exceptions to stable [IamUiFailure] values.
abstract final class IamUiFailureMapper {
  static IamUiFailure from(Object error) {
    if (error is AppException) {
      if (error.code == AppErrorCode.network) {
        return const IamUiFailure(
          code: IamBlockedCodes.systemError,
          message: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.',
          retryable: true,
        );
      }
      if (error.code == AppErrorCode.resendCooldown) {
        return _resendCooldownFailure(error);
      }
      final code = switch (error.code) {
        AppErrorCode.noPermission => IamBlockedCodes.permissionDenied,
        AppErrorCode.notFound => IamBlockedCodes.resourceNotFound,
        'RATE_LIMITED' => IamBlockedCodes.resetRateLimited,
        _ => error.code,
      };
      return _fromCode(code, fallbackMessage: null);
    }
    if (error is IamBlockedException) {
      return _fromCode(error.code, fallbackMessage: error.message);
    }
    if (error is ValidationException) {
      return IamUiFailure(
        code: IamBlockedCodes.validationError,
        message: error.message,
      );
    }
    if (error is ApplicationException) {
      final trimmed = error.message.trim();
      if (_knownCodes.contains(trimmed)) {
        return _fromCode(trimmed, fallbackMessage: error.message);
      }
      final lower = trimmed.toLowerCase();
      if (lower.contains('invalid login') || lower.contains('invalid credential')) {
        return _fromCode(IamBlockedCodes.invalidCredentials);
      }
    }
    if (error is AuthException) {
      final code = error.code?.toLowerCase();
      final msg = error.message.toLowerCase();
      if (code == 'invalid_credentials' ||
          msg.contains('invalid login') ||
          msg.contains('invalid credential')) {
        return _fromCode(IamBlockedCodes.invalidCredentials);
      }
      if (code == 'email_not_confirmed' || msg.contains('not confirmed')) {
        return _fromCode(IamBlockedCodes.identityEmailNotVerified);
      }
      if (code == 'over_email_send_rate_limit' || error.statusCode == '429') {
        final parsed = AppException.from(error);
        if (parsed.code == AppErrorCode.resendCooldown) {
          return _resendCooldownFailure(parsed);
        }
        return _fromCode(IamBlockedCodes.resetRateLimited);
      }
      return IamUiFailure(
        code: IamBlockedCodes.systemError,
        message: error.message.isNotEmpty
            ? error.message
            : _messageFor(IamBlockedCodes.systemError),
        retryable: true,
      );
    }
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('socketexception') ||
        errorString.contains('connection refused') ||
        errorString.contains('clientexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network is unreachable')) {
      return const IamUiFailure(
        code: IamBlockedCodes.systemError,
        message: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.',
        retryable: true,
      );
    }
    return IamUiFailure(
      code: IamBlockedCodes.systemError,
      message: _messageFor(IamBlockedCodes.systemError),
      retryable: true,
    );
  }

  static IamUiFailure _resendCooldownFailure(AppException error) {
    final raw = error.details?['seconds'];
    final seconds = raw is int ? raw : 0;
    return IamUiFailure(
      code: AppErrorCode.resendCooldown,
      message: 'Vui lòng đợi $seconds giây rồi gửi lại.',
    );
  }

  static IamUiFailure _fromCode(String code, {String? fallbackMessage}) {
    // The curated sentence wins whenever the code is known: infra wraps RPC
    // failures as `RpcException(error.toString())`, so [fallbackMessage] is
    // usually a raw `PostgrestException(...)` dump that must never be shown to
    // an end user. Only an unmapped code falls back to it.
    final localized = _localizedMessages[code];
    final message = localized ??
        ((fallbackMessage != null && fallbackMessage.trim().isNotEmpty)
            ? fallbackMessage.trim()
            : _messageFor(code));
    return IamUiFailure(
      code: code,
      message: message,
      retryable: _isRetryable(code),
      requiresReload: code == IamBlockedCodes.stateChanged,
      requiresStepUp: code == IamBlockedCodes.stepUpAuthRequired,
    );
  }

  static bool _isRetryable(String code) {
    return code == IamBlockedCodes.systemError || code == IamBlockedCodes.resetRateLimited;
  }

  static String _messageFor(String code) {
    return _localizedMessages[code] ?? code;
  }

  /// Exact catalog values from [IamBlockedCodes] — not a second string catalog.
  static final Set<String> _knownCodes = <String>{
    IamBlockedCodes.resourceNotFound,
    IamBlockedCodes.validationError,
    IamBlockedCodes.permissionDenied,
    IamBlockedCodes.stateChanged,
    IamBlockedCodes.lastOwnerProtected,
    IamBlockedCodes.membershipInactive,
    IamBlockedCodes.noActiveMembership,
    IamBlockedCodes.membershipRemoved,
    IamBlockedCodes.duplicateMembership,
    IamBlockedCodes.roleNotAssignable,
    IamBlockedCodes.ownerIdentityUnavailable,
    IamBlockedCodes.idempotencyConflict,
    IamBlockedCodes.tenantStateInvalid,
    IamBlockedCodes.tenantSuspended,
    IamBlockedCodes.tenantClosed,
    IamBlockedCodes.systemError,
    IamBlockedCodes.authenticationRequired,
    IamBlockedCodes.sessionExpired,
    IamBlockedCodes.resetRateLimited,
    IamBlockedCodes.resetCodeInvalid,
    IamBlockedCodes.resetCodeExpired,
    IamBlockedCodes.resetCodeAttemptsExceeded,
    IamBlockedCodes.passwordPolicyViolation,
    IamBlockedCodes.invitationTokenInvalid,
    IamBlockedCodes.invitationExpired,
    IamBlockedCodes.invitationRevoked,
    IamBlockedCodes.invitationAlreadyUsed,
    IamBlockedCodes.invitationEmailMismatch,
    IamBlockedCodes.invitationPendingExists,
    IamBlockedCodes.platformUserAlreadyExists,
    IamBlockedCodes.stepUpAuthRequired,
    IamBlockedCodes.ownerTargetInvalid,
    IamBlockedCodes.platformPermissionDenied,
    IamBlockedCodes.platformUserSuspended,
    IamBlockedCodes.invalidCredentials,
    IamBlockedCodes.identityEmailNotVerified,
  };

  static const Map<String, String> _localizedMessages = <String, String>{
    IamBlockedCodes.resourceNotFound: 'Không tìm thấy tài nguyên.',
    IamBlockedCodes.validationError: 'Dữ liệu không hợp lệ.',
    IamBlockedCodes.permissionDenied: 'Bạn không có quyền thực hiện thao tác này.',
    IamBlockedCodes.stateChanged: 'Dữ liệu đã thay đổi. Vui lòng tải lại rồi xác nhận lại.',
    IamBlockedCodes.lastOwnerProtected: 'Không thể thực hiện vì đây là chủ sở hữu cuối cùng.',
    IamBlockedCodes.membershipInactive: 'Thành viên đã tồn tại trong tổ chức.',
    IamBlockedCodes.noActiveMembership:
        'Tài khoản chưa thuộc tổ chức nào đang hoạt động.',
    IamBlockedCodes.membershipRemoved: 'Thành viên đã bị gỡ khỏi tổ chức.',
    IamBlockedCodes.duplicateMembership: 'Thành viên đã tồn tại trong tổ chức.',
    IamBlockedCodes.roleNotAssignable: 'Vai trò không thể gán.',
    IamBlockedCodes.ownerIdentityUnavailable: 'Không xác định được danh tính chủ sở hữu.',
    IamBlockedCodes.idempotencyConflict: 'Yêu cầu trùng với thao tác đang xử lý.',
    IamBlockedCodes.tenantStateInvalid: 'Trạng thái tổ chức không hợp lệ.',
    IamBlockedCodes.tenantSuspended: 'Tổ chức đang bị tạm dừng.',
    IamBlockedCodes.tenantClosed: 'Tổ chức đã đóng.',
    IamBlockedCodes.systemError: 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại.',
    IamBlockedCodes.authenticationRequired: 'Bạn cần đăng nhập lại.',
    IamBlockedCodes.sessionExpired: 'Phiên đăng nhập đã hết hạn.',
    IamBlockedCodes.resetRateLimited: 'Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau.',
    IamBlockedCodes.resetCodeInvalid: 'Mã xác nhận không đúng.',
    IamBlockedCodes.resetCodeExpired: 'Mã xác nhận đã hết hạn.',
    IamBlockedCodes.resetCodeAttemptsExceeded: 'Bạn đã nhập sai mã quá nhiều lần.',
    IamBlockedCodes.passwordPolicyViolation: 'Mật khẩu không đáp ứng chính sách.',
    IamBlockedCodes.invitationTokenInvalid: 'Mã lời mời không hợp lệ.',
    IamBlockedCodes.invitationExpired: 'Lời mời đã hết hạn.',
    IamBlockedCodes.invitationRevoked: 'Lời mời đã bị thu hồi.',
    IamBlockedCodes.invitationAlreadyUsed: 'Lời mời đã được sử dụng.',
    IamBlockedCodes.invitationEmailMismatch: 'Email không khớp với lời mời.',
    IamBlockedCodes.invitationPendingExists: 'Đã có lời mời đang chờ xử lý.',
    IamBlockedCodes.platformUserAlreadyExists: 'Email đã được đăng ký',
    'OTP_INVALID': 'Mã xác minh không đúng hoặc đã hết hạn.',
    'SIGNUP_TENANT_FAILED': 'Không tạo được cửa hàng. Vui lòng kiểm tra thông tin và thử lại.',
    IamBlockedCodes.stepUpAuthRequired: 'Cần xác thực bổ sung để tiếp tục thao tác.',
    IamBlockedCodes.ownerTargetInvalid: 'Đối tượng chủ sở hữu không hợp lệ.',
    IamBlockedCodes.platformPermissionDenied: 'Bạn không có quyền nền tảng cho thao tác này.',
    IamBlockedCodes.platformUserSuspended:
        'Tài khoản của bạn đã bị tạm ngừng. Vui lòng liên hệ quản trị viên.',
    IamBlockedCodes.invalidCredentials: 'Email hoặc mật khẩu không chính xác.',
    IamBlockedCodes.identityEmailNotVerified: 'Email chưa được xác thực hoặc kích hoạt.',
  };
}
