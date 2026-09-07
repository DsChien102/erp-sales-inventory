import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class InvoiceDeliveryStartedDomainEvent extends DomainEventBase {
  InvoiceDeliveryStartedDomainEvent({
    required this.deliveryId,
    required this.electronicInvoiceId,
  });

  final String deliveryId;
  final String electronicInvoiceId;
}
