import 'package:vet45_einvoice_domain/domain.dart';

final class RecordDeliveryResultDto {
  const RecordDeliveryResultDto({
    required this.deliveryStatus,
    required this.displayState,
    required this.hasSecondaryAttention,
  });

  final DeliveryStatus deliveryStatus;

  /// Main invoice display state; a prior success keeps `sent` even when a
  /// later resend fails or becomes unknown.
  final DeliveryDisplayState displayState;

  /// A later problem that must surface separately from [displayState].
  final bool hasSecondaryAttention;
}
