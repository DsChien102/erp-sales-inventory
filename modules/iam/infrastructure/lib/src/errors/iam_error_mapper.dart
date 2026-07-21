import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

ApplicationException mapIamRpcError(RpcException error) {
  final message = error.message.toLowerCase();
  final raw = error.message;

  if (message.contains('not authenticated') ||
      message.contains('jwt') ||
      message.contains('permission denied')) {
    return ApplicationException(raw, cause: error);
  }

  if (message.contains('tenant_access_denied') ||
      message.contains('tenant access denied')) {
    return ApplicationException('TENANT_ACCESS_DENIED', cause: error);
  }

  if (message.contains('tenant_suspended')) {
    return ApplicationException('TENANT_SUSPENDED', cause: error);
  }

  if (message.contains('tenant_closed')) {
    return ApplicationException('TENANT_CLOSED', cause: error);
  }

  return ApplicationException(raw, cause: error);
}
