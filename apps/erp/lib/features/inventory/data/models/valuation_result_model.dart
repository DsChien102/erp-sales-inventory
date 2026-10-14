class ValuationResultLine {
  const ValuationResultLine({
    required this.productName,
    required this.productCode,
    required this.qty,
    required this.uom,
    required this.unitInitial,
    required this.totalValue,
  });

  final String productName;
  final String productCode;
  final double qty;
  final String uom;
  final double unitInitial;
  final double totalValue;
}

class ValuationResultModel {
  const ValuationResultModel({
    required this.operationId,
    required this.receiptNumber,
    required this.supplierName,
    required this.businessDate,
    required this.lines,
    required this.totalValue,
    required this.totalQty,
    this.dirtyScope = const [],
    this.remainingPendingCount = 0,
  });

  final String operationId;
  final String receiptNumber;
  final String supplierName;
  final String businessDate;
  final List<ValuationResultLine> lines;
  final double totalValue;
  final double totalQty;
  final List<String> dirtyScope;
  final int remainingPendingCount;

  bool get hasRemainingPending => remainingPendingCount > 0;
}
