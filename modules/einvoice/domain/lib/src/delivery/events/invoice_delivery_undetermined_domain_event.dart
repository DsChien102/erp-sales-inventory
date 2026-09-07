import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class InvoiceDeliveryUndeterminedDomainEvent extends DomainEventBase {
  InvoiceDeliveryUndeterminedDomainEvent({
    required this.deliveryId,
    required this.electronicInvoiceId,
  });

  final String deliveryId;
  final String electronicInvoiceId;
}
