import 'package:erp/features/sales/data/models.dart';

enum SalesPriceAdjustMode { unitPrice, amountOff, percentOff }

final class SalesManualPriceDraft {
  const SalesManualPriceDraft({
    required this.mode,
    required this.acceptedUnitPrice,
    required this.manualUnitPriceMinor,
    required this.manualDiscountMinor,
    required this.manualDiscountBasisPoints,
    required this.saveAsPrivatePrice,
  });

  final SalesPriceAdjustMode mode;
  final MoneyDto acceptedUnitPrice;
  final int? manualUnitPriceMinor;
  final int? manualDiscountMinor;
  final int? manualDiscountBasisPoints;
  final bool saveAsPrivatePrice;

  SalesManualPriceDraft withAcceptedUnitPrice(MoneyDto value) => SalesManualPriceDraft(
    mode: mode,
    acceptedUnitPrice: value,
    manualUnitPriceMinor: manualUnitPriceMinor,
    manualDiscountMinor: manualDiscountMinor,
    manualDiscountBasisPoints: manualDiscountBasisPoints,
    saveAsPrivatePrice: saveAsPrivatePrice,
  );
}

final class SalesPricingLineRequest {
  const SalesPricingLineRequest({
    required this.localLineId,
    required this.productId,
    required this.productUnitId,
    required this.quantityMicros,
    this.manualUnitPriceMinor,
    this.manualDiscountMinor,
    this.manualDiscountBasisPoints,
  });

  final String localLineId;
  final String productId;
  final String productUnitId;
  final int quantityMicros;
  final int? manualUnitPriceMinor;
  final int? manualDiscountMinor;
  final int? manualDiscountBasisPoints;
}

final class SalesPricingPreviewRequest {
  SalesPricingPreviewRequest({
    required this.customerId,
    required this.currencyCode,
    required this.contextVersion,
    required DateTime effectiveAt,
    required List<SalesPricingLineRequest> lines,
  }) : effectiveAt = effectiveAt.toUtc(),
       lines = List.unmodifiable(lines);

  final String? customerId;
  final String currencyCode;
  final int contextVersion;
  final DateTime effectiveAt;
  final List<SalesPricingLineRequest> lines;
}

final class SalesPricingLineResult {
  SalesPricingLineResult({
    required this.localLineId,
    required this.appliedUnitPrice,
    required this.discount,
    required this.lineTotal,
    required this.sourceCode,
    required this.listUnitPrice,
    required this.floorUnitPrice,
    required List<String> warningCodes,
    required List<String> blockingCodes,
  }) : warningCodes = List.unmodifiable(warningCodes),
       blockingCodes = List.unmodifiable(blockingCodes);

  final String localLineId;
  final MoneyDto appliedUnitPrice;
  final MoneyDto discount;
  final MoneyDto lineTotal;
  final String sourceCode;
  final MoneyDto? listUnitPrice;
  final MoneyDto? floorUnitPrice;
  final List<String> warningCodes;
  final List<String> blockingCodes;
}

final class SalesPricingPreviewResult {
  SalesPricingPreviewResult({
    required this.contextVersion,
    required this.previewToken,
    required this.currencyCode,
    required List<SalesPricingLineResult> lines,
  }) : lines = List.unmodifiable(lines);

  final int contextVersion;
  final String previewToken;
  final String currencyCode;
  final List<SalesPricingLineResult> lines;
}

final class SalesManualPriceRequest {
  const SalesManualPriceRequest({
    required this.customerId,
    required this.productId,
    required this.productUnitId,
    required this.quantityMicros,
    required this.currencyCode,
    required this.contextVersion,
    required this.manualUnitPriceMinor,
    required this.manualDiscountMinor,
    required this.manualDiscountBasisPoints,
    required this.acknowledgeBelowFloor,
  });

  final String? customerId;
  final String productId;
  final String productUnitId;
  final int quantityMicros;
  final String currencyCode;
  final int contextVersion;
  final int? manualUnitPriceMinor;
  final int? manualDiscountMinor;
  final int? manualDiscountBasisPoints;
  final bool acknowledgeBelowFloor;
}

final class SalesManualPriceEvaluation {
  SalesManualPriceEvaluation({
    required this.allowed,
    required this.requiresAcknowledgement,
    required this.normalizedUnitPrice,
    required this.floorUnitPrice,
    required this.canViewFloor,
    required List<String> warningCodes,
    required this.blockingCode,
    required this.message,
  }) : warningCodes = List.unmodifiable(warningCodes);

  final bool allowed;
  final bool requiresAcknowledgement;
  final MoneyDto normalizedUnitPrice;
  final MoneyDto? floorUnitPrice;
  final bool canViewFloor;
  final List<String> warningCodes;
  final String? blockingCode;
  final String? message;
}

final class SalesPrivatePriceSaveRequest {
  const SalesPrivatePriceSaveRequest({
    required this.composeSessionId,
    required this.sourceLineId,
    required this.manualIntentRevision,
    required this.customerId,
    required this.productId,
    required this.productUnitId,
    required this.acceptedUnitPrice,
    required this.currencyCode,
    required this.effectiveFrom,
    required this.contextVersion,
    required this.acknowledgeFloorWarning,
    required this.confirmOverwrite,
  });

  final String composeSessionId;
  final String sourceLineId;
  final int manualIntentRevision;
  final String? customerId;
  final String productId;
  final String productUnitId;
  final MoneyDto acceptedUnitPrice;
  final String currencyCode;
  final DateTime effectiveFrom;
  final int contextVersion;
  final bool acknowledgeFloorWarning;
  final bool confirmOverwrite;

  SalesPrivatePriceSaveRequest copyWith({
    bool? acknowledgeFloorWarning,
    bool? confirmOverwrite,
    bool clearCustomerId = false,
  }) => SalesPrivatePriceSaveRequest(
    composeSessionId: composeSessionId,
    sourceLineId: sourceLineId,
    manualIntentRevision: manualIntentRevision,
    customerId: clearCustomerId ? null : customerId,
    productId: productId,
    productUnitId: productUnitId,
    acceptedUnitPrice: acceptedUnitPrice,
    currencyCode: currencyCode,
    effectiveFrom: effectiveFrom,
    contextVersion: contextVersion,
    acknowledgeFloorWarning: acknowledgeFloorWarning ?? this.acknowledgeFloorWarning,
    confirmOverwrite: confirmOverwrite ?? this.confirmOverwrite,
  );
}

final class SalesPrivatePriceSaveResult {
  const SalesPrivatePriceSaveResult({
    required this.ruleId,
    required this.version,
    required this.created,
    required this.acceptedUnitPrice,
    this.overwriteConfirmationRequired = false,
  });

  final String? ruleId;
  final int? version;
  final bool created;
  final MoneyDto acceptedUnitPrice;
  final bool overwriteConfirmationRequired;
}
