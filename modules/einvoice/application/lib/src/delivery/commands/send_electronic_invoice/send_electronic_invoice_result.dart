import 'package:vet45_einvoice_domain/domain.dart';

final class SendInvoiceResultDto {
  const SendInvoiceResultDto({
    required this.deliveryId, required this.status,
  });

  final String deliveryId;
  final DeliveryStatus status;
}
