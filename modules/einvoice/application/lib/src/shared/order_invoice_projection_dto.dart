import 'package:vet45_einvoice_domain/domain.dart';

import 'order_invoice_action.dart';

/// Read model for Theme 05 order row — issuance + delivery display.
final class OrderInvoiceProjectionDto {
  const OrderInvoiceProjectionDto({
    required this.salesOrderId,
    required this.issuanceDisplayState,
    this.deliveryDisplayState,
    required this.actions,
  });

  final String salesOrderId;
  final IssuanceDisplayState issuanceDisplayState;
  final DeliveryDisplayState? deliveryDisplayState;
  final List<OrderInvoiceAction> actions;
}
