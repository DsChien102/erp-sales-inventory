final class ProviderTemplateDto {
  const ProviderTemplateDto({
    required this.templateId, required this.name, this.serial, this.symbol,
  });

  final String templateId;
  final String name;
  final String? serial;
  final String? symbol;
}
