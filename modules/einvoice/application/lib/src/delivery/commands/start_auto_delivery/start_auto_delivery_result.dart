import '../../shared/auto_delivery_disposition.dart';
import '../../shared/auto_delivery_skip_reason.dart';

final class AutoDeliveryResultDto {
  const AutoDeliveryResultDto({
    required this.disposition,
    this.deliveryId,
    this.skipReason,
  });

  final AutoDeliveryDisposition disposition;
  final String? deliveryId;
  final AutoDeliverySkipReason? skipReason;
}
