import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

PartnerBlockedException mapPartnerRpcError(RpcException error) {
  final message = error.message;
  final upper = message.toUpperCase();

  for (final code in [
    PartnerBlockedCodes.duplicateWarning,
    PartnerBlockedCodes.validationError,
    PartnerBlockedCodes.invalidStatus,
    PartnerBlockedCodes.hasTransactions,
    PartnerBlockedCodes.stateChanged,
    PartnerBlockedCodes.primaryContactOfOrganization,
    PartnerBlockedCodes.notFound,
    PartnerBlockedCodes.noPermission,
  ]) {
    if (upper.contains(code)) {
      return PartnerBlockedException(code, message: message);
    }
  }

  if (message.toLowerCase().contains('permission denied')) {
    return PartnerBlockedException(
      PartnerBlockedCodes.noPermission,
      message: message,
    );
  }

  return PartnerBlockedException(
    PartnerBlockedCodes.systemError,
    message: message,
  );
}
