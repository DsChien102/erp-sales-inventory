import 'money_dto.dart';

final class SalesReceiptAdjustmentSourceDto {
  const SalesReceiptAdjustmentSourceDto({
    required this.sourceKind,
    required this.sourceId,
    required this.amount,
  });

  final String sourceKind;
  final String sourceId;
  final MoneyDto amount;
}

/// Settlement facts at the moment the receipt was generated.
/// Does not replace the original commercial snapshot on the document.
final class SalesReceiptSettlementSnapshotDto {
  const SalesReceiptSettlementSnapshotDto({
    required this.originalPayable,
    required this.adjustment,
    required this.currentPayable,
    required this.collected,
    required this.refunded,
    required this.netCollected,
    required this.outstanding,
    this.adjustmentSources = const [],
  });

  final MoneyDto originalPayable;
  final MoneyDto adjustment;
  final MoneyDto currentPayable;
  final MoneyDto collected;
  final MoneyDto refunded;
  final MoneyDto netCollected;
  final MoneyDto outstanding;
  final List<SalesReceiptAdjustmentSourceDto> adjustmentSources;
}
