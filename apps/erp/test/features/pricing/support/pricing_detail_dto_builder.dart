import 'package:erp/features/pricing/data/models.dart';

CustomerPriceRuleDetailDto buildPricingDetailDto({
  String id = 'rule-1',
  CustomerPriceRuleSourceType sourceType = CustomerPriceRuleSourceType.manual,
  CustomerPriceRuleStatus persistedStatus = CustomerPriceRuleStatus.active,
  CustomerPriceRuleDerivedStatus derivedStatus =
      CustomerPriceRuleDerivedStatus.applying,
  String? note,
  int priceMinor = 90000,
  DateTime? disabledAt,
  String? disabledBy,
  String? disabledReason,
  List<String> availableActions = const [],
  String? updatedByName,
  String? disabledByName,
}) {
  final at = DateTime.utc(2026, 7, 16);
  return CustomerPriceRuleDetailDto(
    id: id,
    customer: const CustomerRefDto(
      customerId: '00000000-0000-4000-8000-000000000002',
      displayName: 'Phòng khám A',
      status: 'active',
    ),
    productUnit: const ProductUnitRefDto(
      productId: '00000000-0000-4000-8000-000000000003',
      productName: 'Vaccine A',
      productUnitId: '00000000-0000-4000-8000-000000000004',
      unitName: 'Lọ',
      sellableStatus: 'active',
    ),
    price: MoneyDto(amountMinor: priceMinor, currencyCode: 'VND'),
    effectivePeriod: EffectivePeriodDto(effectiveFrom: at),
    ruleType: CustomerPriceRuleType.specialPrice,
    sourceType: sourceType,
    persistedStatus: persistedStatus,
    derivedStatus: derivedStatus,
    note: note,
    validationOutcome: const RuleValidationOutcomeDto(
      outcome: 'notChecked',
      warningCodes: [],
      blockingCodes: [],
      floorPriceHidden: true,
    ),
    referenceHealth: const CustomerPriceRuleReferenceHealthDto(
      customerState: CustomerPriceRuleReferenceState.valid,
      productUnitState: CustomerPriceRuleReferenceState.valid,
      priceBandState: CustomerPriceRulePriceBandState.current,
      issueCodes: [],
      usedStoredPriceBandSnapshot: false,
    ),
    sourceTrace: const CustomerPriceRuleSourceTraceDto(hidden: false),
    createdBy: '00000000-0000-4000-8000-000000000005',
    createdAt: at,
    updatedBy: '00000000-0000-4000-8000-000000000005',
    updatedAt: at,
    version: 1,
    availableActions: availableActions,
    disabledAt: disabledAt,
    disabledBy: disabledBy,
    disabledReason: disabledReason,
    updatedByName: updatedByName,
    disabledByName: disabledByName,
  );
}
