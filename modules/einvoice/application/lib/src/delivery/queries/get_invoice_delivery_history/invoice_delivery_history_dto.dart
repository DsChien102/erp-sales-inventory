import 'package:vet45_einvoice_domain/domain.dart';
import 'invoice_delivery_item_dto.dart';

final class InvoiceDeliveryHistoryDto {
  const InvoiceDeliveryHistoryDto({
    required this.deliveries,
    required this.displayState,
  });

  final List<InvoiceDeliveryItemDto> deliveries;
  final DeliveryDisplayState displayState;
}
