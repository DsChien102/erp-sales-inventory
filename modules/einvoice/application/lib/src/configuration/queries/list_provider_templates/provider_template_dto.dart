final class ProviderTemplateDto {
  const ProviderTemplateDto({
    required this.templateId,
    required this.name,
    this.serial,
    this.symbol,
    this.invoiceSeries,
    this.invoiceWithCode,
    this.isMtt,
    this.isSendSummary,
  });

  final String templateId;
  final String name;
  final String? serial;
  final String? symbol;
  final String? invoiceSeries;
  final bool? invoiceWithCode;
  final bool? isMtt;
  final bool? isSendSummary;
}
