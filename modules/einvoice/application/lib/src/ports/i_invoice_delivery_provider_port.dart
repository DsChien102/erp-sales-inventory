import '../delivery/shared/delivery_provider_context_dto.dart';
import '../delivery/shared/delivery_provider_outcome.dart';

abstract interface class IInvoiceDeliveryProviderPort {
  Future<DeliveryProviderOutcome> sendEmail(DeliveryProviderContextDto context);
}
