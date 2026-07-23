import 'customer_price_rule_import_enums.dart';

final class CustomerPriceRuleImportRowPreviewDto {
  const CustomerPriceRuleImportRowPreviewDto({
    required this.id,
    required this.rowNumber,
    required this.ruleId,
    required this.customerId,
    required this.productId,
    required this.productUnitId,
    required this.price,
    required this.effectiveFrom,
    required this.effectiveTo,
    required this.note,
    required this.status,
    required this.action,
    required this.errorCodes,
    required this.warningCodes,
    this.customerSnapshot,
    this.productSnapshot,
    this.unitSnapshot,
    this.unitResolutionStrategy,
    this.normalizedPriceMinor,
    this.normalizedEffectiveFrom,
    this.normalizedEffectiveTo,
    this.normalizedNote,
    this.matchedRuleId,
    this.matchedRuleVersion,
    this.affectedRuleId,
  });

  final String id;
  final int rowNumber;
  final String? ruleId;
  final String? customerId;
  final String? productId;
  final String? productUnitId;
  final String? price;
  final String? effectiveFrom;
  final String? effectiveTo;
  final String? note;
  final Map<String, dynamic>? customerSnapshot;
  final Map<String, dynamic>? productSnapshot;
  final Map<String, dynamic>? unitSnapshot;
  final ProductUnitResolutionStrategy? unitResolutionStrategy;
  final int? normalizedPriceMinor;
  final DateTime? normalizedEffectiveFrom;
  final DateTime? normalizedEffectiveTo;
  final String? normalizedNote;
  final CustomerPriceRuleImportRowStatus status;
  final CustomerPriceRuleImportAction action;
  final List<String> errorCodes;
  final List<String> warningCodes;
  final String? matchedRuleId;
  final int? matchedRuleVersion;
  final String? affectedRuleId;
}
