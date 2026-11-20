import 'package:erp/features/sales/data/models.dart';

final class SalesReturnExchangeDetailVm {
  const SalesReturnExchangeDetailVm({
    required this.returnExchangeId,
    required this.salesOrderId,
    required this.referenceNumber,
    required this.status,
    required this.version,
    required this.lines,
    required this.valuation,
    required this.settlementPlan,
    required this.completionReady,
    this.entrySource,
    this.createdAt,
    this.confirmedByActorId,
    this.confirmedAt,
    this.completedAt,
  });

  final String returnExchangeId;
  final String salesOrderId;
  final String referenceNumber;
  final ReturnExchangeStatus status;
  final int version;
  final ReturnExchangeEntrySource? entrySource;
  final DateTime? createdAt;
  final String? confirmedByActorId;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final List<ReturnExchangeDetailLineDto> lines;
  final ReturnExchangeValuationDto valuation;
  final ReturnExchangeSettlementPlanDto settlementPlan;
  final bool completionReady;
}
