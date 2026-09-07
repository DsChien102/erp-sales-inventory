import 'i_einvoice_internal_command_client.dart';

abstract interface class IEinvoiceInternalCommandDeadLetterHandler {
  Future<void> handleDeadLetter({
    required String tenantId,
    required ClaimedInternalCommand command,
    required Object error,
  });
}
