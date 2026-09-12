final class SalesReturnExchangeSettlementVm {
  const SalesReturnExchangeSettlementVm({
    required this.returnExchangeId,
    required this.currencyCode,
    required this.netDifferenceMinor,
    required this.storeRefundMinor,
    required this.customerCollectMinor,
    required this.receivableCreateMinor,
    required this.receivableReverseMinor,
    required this.sourceOrderVersion,
    required this.sourceSettlementVersion,
    this.pricingSourceVersion,
  });

  final String returnExchangeId;
  final String currencyCode;
  final int netDifferenceMinor;
  final int storeRefundMinor;
  final int customerCollectMinor;
  final int receivableCreateMinor;
  final int receivableReverseMinor;
  final int sourceOrderVersion;
  final int sourceSettlementVersion;
  final int? pricingSourceVersion;
}
