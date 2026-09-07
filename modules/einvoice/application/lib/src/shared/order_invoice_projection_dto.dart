import 'package:vet45_einvoice_domain/domain.dart';

import 'order_invoice_action.dart';

/// Read model for Theme 05 order row — issuance + delivery display.
final class OrderInvoiceProjectionDto {
  const OrderInvoiceProjectionDto({
    required this.salesOrderId,
    required this.issuanceDisplayState,
    this.deliveryDisplayState,
    this.hasSecondaryAttention = false,
    this.deliveryPending = false,
    required this.actions,
  });

  final bool deliveryPending;
  final String salesOrderId;
  final IssuanceDisplayState issuanceDisplayState;
  final DeliveryDisplayState? deliveryDisplayState;

  /// Later failed/unknown delivery attention while main display stays `sent`.
  final bool hasSecondaryAttention;
  final List<OrderInvoiceAction> actions;
}
