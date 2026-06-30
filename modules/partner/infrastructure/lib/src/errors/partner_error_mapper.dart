import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

ApplicationException mapPartnerRpcError(RpcException error) {
  final message = error.message.toLowerCase();

  if (message.contains('duplicate confirmation required')) {
    return ApplicationException(
      'Duplicate partner data requires confirmation before saving.',
      cause: error,
    );
  }

  if (message.contains('not authenticated') ||
      message.contains('permission denied') ||
      message.contains('actor mismatch')) {
    return ApplicationException(error.message, cause: error);
  }

  return ApplicationException(error.message, cause: error);
}
