import '../delivery/shared/delivery_observation_context_dto.dart';
import '../delivery/shared/delivery_observation_outcome.dart';

abstract interface class IInvoiceDeliveryObservationProviderPort {
  Future<DeliveryObservationOutcome> observe(
    DeliveryObservationContextDto context,
  );
}
