import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class InvoiceDeliverySucceededDomainEvent extends DomainEventBase {
  InvoiceDeliverySucceededDomainEvent({
    required this.deliveryId,
    required this.electronicInvoiceId,
  });

  final String deliveryId;
  final String electronicInvoiceId;
}
