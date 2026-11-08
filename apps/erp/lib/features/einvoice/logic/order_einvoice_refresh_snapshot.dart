import 'package:erp/features/einvoice/data/models.dart';

final class OrderEInvoiceRefreshSnapshot {
  const OrderEInvoiceRefreshSnapshot({
    required this.projection,
    this.readiness,
    this.attemptStatus,
  });

  final OrderInvoiceProjectionDto projection;
  final IssuanceReadinessDto? readiness;
  final IssuanceAttemptStatusDto? attemptStatus;
}
