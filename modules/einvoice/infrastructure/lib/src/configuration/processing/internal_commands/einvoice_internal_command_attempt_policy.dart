import 'package:vet45_einvoice_application/application.dart';

/// Frozen attempt limits — observation and older commands keep generic policy.
const maxAttemptsByCommandType = <String, int>{
  FetchOfficialInvoiceViewCommand.type: 2,
  DownloadInvoiceDocumentCommand.type: 3,
  SendInvoiceEmailCommand.type: 3,
  ReconcileInvoiceDeliveryCommand.type: 3,
};

int? maxAttemptsForCommandType(String commandType) =>
    maxAttemptsByCommandType[commandType];
