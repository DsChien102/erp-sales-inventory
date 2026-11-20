final class MoneyDto {
  const MoneyDto({required this.amountMinor, required this.currencyCode});

  final int amountMinor;
  final String currencyCode;
}

final class EffectivePeriodDto {
  const EffectivePeriodDto({required this.effectiveFrom, this.effectiveTo});

  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
}

final class CursorPageDto<T> {
  const CursorPageDto({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<T> items;
  final String? nextCursor;
  final bool hasMore;
}

final class RuleIssueDto {
  const RuleIssueDto({required this.code, this.field, this.details = const {}});

  final String code;
  final String? field;
  final Map<String, Object?> details;
}

final class RuleValidationOutcomeDto {
  const RuleValidationOutcomeDto({
    required this.outcome,
    required this.warningCodes,
    required this.blockingCodes,
    required this.floorPriceHidden,
    this.listPrice,
    this.floorPrice,
  });

  final String outcome;
  final List<String> warningCodes;
  final List<String> blockingCodes;
  final MoneyDto? listPrice;
  final MoneyDto? floorPrice;
  final bool floorPriceHidden;
}

final class CustomerRefDto {
  const CustomerRefDto({
    required this.customerId,
    required this.displayName,
    this.phone,
    required this.status,
  });

  final String customerId;
  final String displayName;
  final String? phone;
  final String status;
}

final class ProductUnitRefDto {
  const ProductUnitRefDto({
    required this.productId,
    required this.productName,
    required this.productUnitId,
    required this.unitName,
    required this.sellableStatus,
    this.productReferenceId,
    this.sku,
  });

  final String productId;
  final String productName;
  final String productUnitId;
  final String unitName;
  final String sellableStatus;
  final String? productReferenceId;
  final String? sku;
}

abstract final class CustomerPriceRuleAvailableActions {
  static const edit = 'edit';
  static const disable = 'disable';
  static const reenable = 'reenable';
  static const history = 'history';
}

abstract final class PricingAvailableActions {
  static const createManual = 'create_manual';
  static const import = 'import';
}

