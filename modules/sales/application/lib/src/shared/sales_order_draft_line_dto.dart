import 'money_dto.dart';
import 'quantity_dto.dart';

final class SalesOrderDraftLineDto {
  SalesOrderDraftLineDto({
    required this.lineId,
    required this.productId,
    required this.productSku,
    required this.productName,
    required this.productUnitId,
    required this.unitCode,
    required this.unitName,
    required this.quantity,
    required this.appliedUnitPrice,
    required this.lineTotal,
    this.listUnitPrice,
    this.manualUnitPriceMinor,
    this.manualDiscountMinor,
    this.manualDiscountBasisPoints,
    this.pricingSourceCode,
    List<String> pricingWarningCodes = const [],
    List<String> pricingBlockingCodes = const [],
    this.note,
    this.needsRevalidation = false,
  }) : pricingWarningCodes = List.unmodifiable(pricingWarningCodes),
       pricingBlockingCodes = List.unmodifiable(pricingBlockingCodes);

  final String lineId;
  final String productId;
  final String productSku;
  final String productName;
  final String productUnitId;
  final String unitCode;
  final String unitName;
  final QuantityDto quantity;
  final MoneyDto appliedUnitPrice;
  final MoneyDto lineTotal;
  final MoneyDto? listUnitPrice;
  final int? manualUnitPriceMinor;
  final int? manualDiscountMinor;
  final int? manualDiscountBasisPoints;
  final String? pricingSourceCode;
  final List<String> pricingWarningCodes;
  final List<String> pricingBlockingCodes;
  final String? note;
  final bool needsRevalidation;
}
