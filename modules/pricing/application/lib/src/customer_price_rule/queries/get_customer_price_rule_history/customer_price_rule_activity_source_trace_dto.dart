final class CustomerPriceRuleActivitySourceTraceDto {
  const CustomerPriceRuleActivitySourceTraceDto({
    this.importId,
    this.importRowId,
    this.orderId,
    this.orderLineId,
    this.memoryRequestId,
    this.soldAt,
  });

  final String? importId;
  final String? importRowId;
  final String? orderId;
  final String? orderLineId;
  final String? memoryRequestId;
  final DateTime? soldAt;
}
