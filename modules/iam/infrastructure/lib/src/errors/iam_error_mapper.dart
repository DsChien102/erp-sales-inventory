import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

ApplicationException mapIamRpcError(RpcException error) {
  final message = error.message.toLowerCase();

  if (message.contains('not authenticated') ||
      message.contains('jwt') ||
      message.contains('permission denied')) {
    return ApplicationException(error.message, cause: error);
  }

  if (message.contains('tenant access denied')) {
    return ApplicationException(error.message, cause: error);
  }

  return ApplicationException(error.message, cause: error);
}
