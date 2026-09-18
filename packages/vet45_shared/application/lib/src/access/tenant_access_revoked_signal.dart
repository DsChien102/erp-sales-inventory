import 'dart:async';

/// Process-wide signal raised when the server rejects a call because the
/// current tenant is no longer operational (suspended / closed).
///
/// Emitted by the Supabase RPC client; UI shells listen and leave the tenant.
abstract final class TenantAccessRevokedSignal {
  static const tenantSuspended = 'TENANT_SUSPENDED';
  static const tenantClosed = 'TENANT_CLOSED';

  static final StreamController<String> _controller =
      StreamController<String>.broadcast();

  static Stream<String> get stream => _controller.stream;

  /// Emits [tenantSuspended] / [tenantClosed] when [error] carries that code.
  static void notifyFromError(Object error) {
    final text = error.toString().toUpperCase();
    if (text.contains(tenantClosed)) {
      _controller.add(tenantClosed);
    } else if (text.contains(tenantSuspended)) {
      _controller.add(tenantSuspended);
    }
  }
}
