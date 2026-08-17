import 'package:vet45_einvoice_domain/domain.dart';

final class RecordDeliveryResultDto {
  const RecordDeliveryResultDto({
    required this.deliveryStatus, required this.displayState,
  });

  final DeliveryStatus deliveryStatus;
  final DeliveryDisplayState displayState;
}
