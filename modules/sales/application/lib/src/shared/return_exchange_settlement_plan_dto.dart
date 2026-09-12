final class ReturnExchangeSettlementPlanDto {
  const ReturnExchangeSettlementPlanDto({
    required this.currencyCode,
    required this.netDifferenceMinor,
    required this.collectAmountMinor,
    required this.refundAmountMinor,
    required this.receivableCreateAmountMinor,
    required this.receivableReverseAmountMinor,
    required this.processedCollectMinor,
    required this.processedRefundMinor,
    required this.pendingReceivableCreateMinor,
    required this.pendingReceivableReverseMinor,
    required this.remainderCollectMinor,
    required this.remainderRefundMinor,
    required this.sourceOrderVersion,
    required this.sourceSettlementVersion,
    this.pricingSourceVersion,
  });

  final String currencyCode;
  final int netDifferenceMinor;
  final int collectAmountMinor;
  final int refundAmountMinor;
  final int receivableCreateAmountMinor;
  final int receivableReverseAmountMinor;
  final int processedCollectMinor;
  final int processedRefundMinor;
  final int pendingReceivableCreateMinor;
  final int pendingReceivableReverseMinor;
  final int remainderCollectMinor;
  final int remainderRefundMinor;
  final int sourceOrderVersion;
  final int sourceSettlementVersion;
  final int? pricingSourceVersion;
}
