import 'package:vet45_einvoice_domain/domain.dart';
import 'invoice_delivery_item_dto.dart';

final class InvoiceDeliveryHistoryDto {
  const InvoiceDeliveryHistoryDto({
    required this.deliveries,
    required this.displayState,
    required this.hasSecondaryAttention,
  });

  final List<InvoiceDeliveryItemDto> deliveries;

  /// Main invoice display state; a prior success keeps `sent`.
  final DeliveryDisplayState displayState;

  /// A later failed or unknown delivery that needs separate attention.
  final bool hasSecondaryAttention;
}
