import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

EInvoiceBlockedException mapEinvoiceRpcError(RpcException error) {
  final message = error.message;
  final upper = message.toUpperCase();

  for (final code in [
    EInvoiceBlockedCodes.noPermission,
    EInvoiceBlockedCodes.notFound,
    EInvoiceBlockedCodes.validationError,
    EInvoiceBlockedCodes.invalidStatus,
    EInvoiceBlockedCodes.stateChanged,
    EInvoiceBlockedCodes.providerNotConnected,
    EInvoiceBlockedCodes.providerAuthFailed,
    EInvoiceBlockedCodes.providerUnavailable,
    EInvoiceBlockedCodes.configNotReady,
  ]) {
    if (upper.contains(code)) {
      return EInvoiceBlockedException(code, message: message);
    }
  }

  if (message.toLowerCase().contains('permission denied')) {
    return EInvoiceBlockedException(
      EInvoiceBlockedCodes.noPermission,
      message: message,
    );
  }

  return EInvoiceBlockedException(
    EInvoiceBlockedCodes.systemError,
    message: message,
  );
}
