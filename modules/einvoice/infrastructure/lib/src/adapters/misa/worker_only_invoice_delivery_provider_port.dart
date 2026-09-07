import 'package:vet45_einvoice_application/application.dart';

/// Client-host guard preventing ERP from performing slice-5 MISA delivery HTTP.
final class WorkerOnlyInvoiceDeliveryProviderPort
    implements IInvoiceDeliveryProviderPort {
  Never _reject() {
    throw StateError('MISA invoice delivery HTTP operations are worker-only');
  }

  @override
  Future<DeliveryProviderOutcome> sendEmail(
    DeliveryProviderContextDto context,
  ) async => _reject();
}
