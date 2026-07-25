import 'customer_price_rule_import_dto.dart';

final class CustomerPriceRuleImportResultDto {
  const CustomerPriceRuleImportResultDto({
    required this.batch,
    required this.processedAt,
    required this.isReplay,
  });

  final CustomerPriceRuleImportDto batch;
  final DateTime processedAt;
  final bool isReplay;
}
