import 'dart:async';

/// Process-wide signal raised when the server rejects a call because the
/// current tenant is no longer operational (suspended / closed), or the
/// platform user account itself is suspended.
///
/// Emitted by the Supabase RPC client; UI shells listen and leave the tenant
/// or sign out (platform user suspended).
abstract final class TenantAccessRevokedSignal {
  static const tenantSuspended = 'TENANT_SUSPENDED';
  static const tenantClosed = 'TENANT_CLOSED';
  static const platformUserSuspended = 'PLATFORM_USER_SUSPENDED';

  /// Không có quyền trên RPC. Có thể là quyền thường, hoặc thành viên vừa bị loại.
  /// TODO(P9): chuyển vào core/session.
  static const permissionDenied = 'PERMISSION_DENIED';

  static final StreamController<String> _controller =
      StreamController<String>.broadcast();

  static Stream<String> get stream => _controller.stream;

  /// Emits [platformUserSuspended] / [tenantClosed] / [tenantSuspended] /
  /// [permissionDenied] when [error] carries that code.
  /// Mã cụ thể đứng trước [permissionDenied] để không nuốt tạm ngừng / đóng.
  static void notifyFromError(Object error) {
    final text = error.toString().toUpperCase();
    // Tài khoản bị tạm ngừng ưu tiên cao nhất: chặn ở mọi tổ chức.
    if (text.contains(platformUserSuspended)) {
      _controller.add(platformUserSuspended);
    } else if (text.contains(tenantClosed)) {
      _controller.add(tenantClosed);
    } else if (text.contains(tenantSuspended)) {
      _controller.add(tenantSuspended);
    } else if (text.contains(permissionDenied)) {
      _controller.add(permissionDenied);
    }
  }
}
