import 'package:vet45_einvoice_application/application.dart';

/// Explicit unsupported observation adapter for current MISA meInvoice.
///
/// Never performs HTTP and never treats invoice `getStatus` as delivery
/// evidence. Future providers with a real delivery-observation contract must
/// implement a separate adapter.
final class MeInvoiceDeliveryObservationProviderAdapter
    implements IInvoiceDeliveryObservationProviderPort {
  const MeInvoiceDeliveryObservationProviderAdapter();

  @override
  Future<DeliveryObservationOutcome> observe(
    DeliveryObservationContextDto context,
  ) async {
    return const DeliveryObservationUnsupported();
  }
}
