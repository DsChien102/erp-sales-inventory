import 'delivery_provider_context_dto.dart';

sealed class PrepareDeliveryProviderCallResult {
  const PrepareDeliveryProviderCallResult();
}

/// Dispatch barrier crossed; caller may perform exactly one provider HTTP call.
final class PrepareDeliveryCallProvider extends PrepareDeliveryProviderCallResult {
  const PrepareDeliveryCallProvider({
    required this.providerContext,
    required this.deliveryVersion,
  });

  final DeliveryProviderContextDto providerContext;
  final int deliveryVersion;
}

/// Attempt/delivery already terminal or superseded; acknowledge without HTTP.
final class PrepareDeliverySkip extends PrepareDeliveryProviderCallResult {
  const PrepareDeliverySkip();
}

/// Replay found SUBMITTED without a terminal result; record UNKNOWN without HTTP.
final class PrepareDeliveryRecordUnknown extends PrepareDeliveryProviderCallResult {
  const PrepareDeliveryRecordUnknown({
    required this.deliveryVersion,
  });

  final int deliveryVersion;
}
