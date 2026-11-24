import 'pricing_common.dart';
import 'pricing_enums.dart';

final class CustomerPriceRuleDetailDto {
  const CustomerPriceRuleDetailDto({
    required this.id,
    required this.customer,
    required this.productUnit,
    required this.price,
    required this.effectivePeriod,
    required this.ruleType,
    required this.sourceType,
    required this.persistedStatus,
    required this.derivedStatus,
    required this.validationOutcome,
    required this.referenceHealth,
    required this.sourceTrace,
    required this.createdBy,
    required this.createdAt,
    required this.updatedBy,
    required this.updatedAt,
    required this.version,
    required this.availableActions,
    this.note,
    this.disabledAt,
    this.disabledBy,
    this.disabledReason,
    this.deletedAt,
    this.updatedByName,
    this.disabledByName,
  });

  final String id;
  final CustomerRefDto customer;
  final ProductUnitRefDto productUnit;
  final MoneyDto price;
  final EffectivePeriodDto effectivePeriod;
  final CustomerPriceRuleType ruleType;
  final CustomerPriceRuleSourceType sourceType;
  final CustomerPriceRuleStatus persistedStatus;
  final CustomerPriceRuleDerivedStatus derivedStatus;
  final String? note;
  final RuleValidationOutcomeDto validationOutcome;
  final CustomerPriceRuleReferenceHealthDto referenceHealth;
  final CustomerPriceRuleSourceTraceDto sourceTrace;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;
  final int version;
  final List<String> availableActions;
  final DateTime? disabledAt;
  final String? disabledBy;
  final String? disabledReason;
  final DateTime? deletedAt;
  final String? updatedByName;
  final String? disabledByName;
}

final class CustomerPriceRuleReferenceHealthDto {
  const CustomerPriceRuleReferenceHealthDto({
    required this.customerState,
    required this.productUnitState,
    required this.priceBandState,
    required this.issueCodes,
    required this.usedStoredPriceBandSnapshot,
  });

  final CustomerPriceRuleReferenceState customerState;
  final CustomerPriceRuleReferenceState productUnitState;
  final CustomerPriceRulePriceBandState priceBandState;
  final List<String> issueCodes;
  final bool usedStoredPriceBandSnapshot;
}

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

final class CustomerPriceRuleListItemDto {
  const CustomerPriceRuleListItemDto({
    required this.id,
    required this.customer,
    required this.productUnit,
    required this.price,
    required this.effectivePeriod,
    required this.ruleType,
    required this.sourceType,
    required this.persistedStatus,
    required this.derivedStatus,
    required this.validationOutcome,
    required this.updatedAt,
  });

  final String id;
  final CustomerRefDto customer;
  final ProductUnitRefDto productUnit;
  final MoneyDto price;
  final EffectivePeriodDto effectivePeriod;
  final CustomerPriceRuleType ruleType;
  final CustomerPriceRuleSourceType sourceType;
  final CustomerPriceRuleStatus persistedStatus;
  final CustomerPriceRuleDerivedStatus derivedStatus;
  final RuleValidationOutcomeDto validationOutcome;
  final DateTime updatedAt;
}

final class CustomerPriceRuleSearchResultDto {
  const CustomerPriceRuleSearchResultDto({
    required this.page,
    required this.availableActions,
    required this.totalCount,
  });

  final CursorPageDto<CustomerPriceRuleListItemDto> page;
  final List<String> availableActions;
  final int totalCount;
}

final class CreateCustomerPriceRuleResult {
  const CreateCustomerPriceRuleResult({
    required this.rule,
    required this.warnings,
  });

  final CustomerPriceRuleDetailDto rule;
  final List<RuleIssueDto> warnings;
}

final class CustomerPriceRuleReenablePrecheckDto {
  const CustomerPriceRuleReenablePrecheckDto({
    required this.validationOutcome,
    required this.precheckToken,
    required this.ruleVersion,
    required this.businessDate,
  });

  final RuleValidationOutcomeDto validationOutcome;
  final String precheckToken;
  final int ruleVersion;
  final DateTime businessDate;
}

final class ApplicableCustomerPriceRuleDto {
  const ApplicableCustomerPriceRuleDto({
    required this.ruleId,
    required this.price,
    required this.effectivePeriod,
    required this.sourceType,
    required this.version,
  });

  final String ruleId;
  final MoneyDto price;
  final EffectivePeriodDto effectivePeriod;
  final CustomerPriceRuleSourceType sourceType;
  final int version;
}

final class ResolveApplicableCustomerPriceRuleResultDto {
  const ResolveApplicableCustomerPriceRuleResultDto({this.rule});

  final ApplicableCustomerPriceRuleDto? rule;
}

