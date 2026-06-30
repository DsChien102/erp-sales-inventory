import 'package:uuid/uuid.dart';
import 'package:vet45_shared_application/application.dart';

import 'iam_session.dart';

final class IamExecutionContext implements IExecutionContext {
  IamExecutionContext({
    required IamSession session,
    String? correlationId,
  }) : _session = session,
       correlationId = correlationId ?? const Uuid().v4();

  final IamSession _session;

  @override
  final String correlationId;

  @override
  Future<String> requireUserId() async {
    final userId = _session.userId;
    if (userId == null) {
      throw ApplicationException('User is required');
    }
    return userId;
  }

  @override
  Future<String> requireTenantId() async {
    final tenantId = _session.tenantId;
    if (tenantId == null) {
      throw ApplicationException('Tenant is required');
    }
    return tenantId;
  }
}
