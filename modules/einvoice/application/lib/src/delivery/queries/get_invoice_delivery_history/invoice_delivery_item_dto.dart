import 'package:vet45_einvoice_domain/domain.dart';

final class InvoiceDeliveryItemDto {
  const InvoiceDeliveryItemDto({
    required this.deliveryId, required this.recipientEmail, required this.status, this.sentAt,
  });

  final String deliveryId;
  final String recipientEmail;
  final DeliveryStatus status;
  final DateTime? sentAt;
}
