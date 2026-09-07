import 'package:vet45_einvoice_application/application.dart';

/// In-memory [IInvoiceDeliveryProviderPort] for worker-handler tests.
final class FakeInvoiceDeliveryProviderPort implements IInvoiceDeliveryProviderPort {
  DeliveryProviderOutcome outcome = const DeliveryProviderSucceeded();
  int sendCalls = 0;
  bool throwOnSend = false;
  DeliveryProviderContextDto? lastContext;

  @override
  Future<DeliveryProviderOutcome> sendEmail(
    DeliveryProviderContextDto context,
  ) async {
    sendCalls++;
    lastContext = context;
    if (throwOnSend) {
      throw StateError('simulated provider transport failure');
    }
    return outcome;
  }
}
