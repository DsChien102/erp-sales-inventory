import '../enums/delivery_display_state.dart';
import '../enums/delivery_status.dart';

/// Main display state plus secondary attention for an invoice's deliveries.
final class DeliveryDisplayProjection {
  const DeliveryDisplayProjection({
    required this.displayState,
    required this.hasSecondaryAttention,
  });

  final DeliveryDisplayState displayState;
  final bool hasSecondaryAttention;
}

/// Projects Theme-05 delivery display state from authoritative history.
abstract final class DeliveryDisplayStatePolicy {
  const DeliveryDisplayStatePolicy._();

  static DeliveryDisplayProjection project(
    Iterable<DeliveryStatus> historyStatuses,
  ) {
    final statuses = historyStatuses.toList(growable: false);
    if (statuses.isEmpty) {
      return const DeliveryDisplayProjection(
        displayState: DeliveryDisplayState.notSent,
        hasSecondaryAttention: false,
      );
    }

    final hasSuccess = statuses.contains(DeliveryStatus.succeeded);
    if (hasSuccess) {
      final latest = statuses.last;
      final needsAttention = latest == DeliveryStatus.failed || latest == DeliveryStatus.unknown;
      return DeliveryDisplayProjection(
        displayState: DeliveryDisplayState.sent,
        hasSecondaryAttention: needsAttention,
      );
    }

    if (statuses.contains(DeliveryStatus.processing)) {
      return const DeliveryDisplayProjection(
        displayState: DeliveryDisplayState.sending,
        hasSecondaryAttention: false,
      );
    }

    if (statuses.contains(DeliveryStatus.unknown)) {
      return const DeliveryDisplayProjection(
        displayState: DeliveryDisplayState.unknown,
        hasSecondaryAttention: false,
      );
    }

    return const DeliveryDisplayProjection(
      displayState: DeliveryDisplayState.failed,
      hasSecondaryAttention: false,
    );
  }
}
