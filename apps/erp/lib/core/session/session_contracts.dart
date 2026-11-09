import 'package:uuid/uuid.dart';
import 'package:vet45_shared_application/application.dart';

import 'session_store.dart';

/// Ngữ cảnh thực thi cho các module nghiệp vụ cũ, đọc từ [SessionStore].
///
/// Giữ nguyên chuỗi lỗi (`User is required`, `Tenant is required`): các mapper
/// của module cũ so khớp theo chuỗi.
final class CoreExecutionContext implements IExecutionContext, ICurrentUser, ICurrentTenant {
  CoreExecutionContext({required SessionStore store, String? correlationId})
    : _store = store,
      correlationId = correlationId ?? const Uuid().v4();

  final SessionStore _store;

  @override
  final String correlationId;

  @override
  String? get userId => _store.userId;

  @override
  String? get tenantId => _store.tenantId;

  @override
  Future<String> requireUserId() async {
    final userId = _store.userId;
    if (userId == null) {
      throw const ApplicationException('User is required');
    }
    return userId;
  }

  @override
  Future<String> requireTenantId() async {
    final tenantId = _store.tenantId;
    if (tenantId == null) {
      throw const ApplicationException('Tenant is required');
    }
    return tenantId;
  }
}
