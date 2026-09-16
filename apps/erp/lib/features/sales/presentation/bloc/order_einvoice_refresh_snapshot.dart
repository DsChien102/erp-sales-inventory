import 'package:vet45_einvoice_application/application.dart';

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
