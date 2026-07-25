final class CustomerPriceRuleSourceTraceDto {
  const CustomerPriceRuleSourceTraceDto({
    required this.hidden,
    this.sourceImportId,
    this.sourceImportRowId,
    this.sourceOrderId,
    this.sourceOrderLineId,
    this.sourceMemoryRequestId,
  });

  final bool hidden;
  final String? sourceImportId;
  final String? sourceImportRowId;
  final String? sourceOrderId;
  final String? sourceOrderLineId;
  final String? sourceMemoryRequestId;
}
