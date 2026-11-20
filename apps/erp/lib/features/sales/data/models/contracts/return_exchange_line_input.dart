import 'money_dto.dart';
import 'quantity_dto.dart';
import 'product_snapshot_dto.dart';
import 'product_unit_snapshot_dto.dart';
import 'sales_contract_enums.dart';

final class ReturnExchangeLineInput {
  const ReturnExchangeLineInput({
    required this.kind,
    required this.productId,
    required this.productUnitId,
    required this.quantity,
    this.originalSalesOrderLineId,
    this.sourceExchangeLineId,
    this.reasonCode,
    this.conditionCode,
    this.exchangeProductSnapshot,
    this.exchangeUnitSnapshot,
    this.exchangeUnitPrice,
  });

  final ReturnExchangeLineKind kind;
  final String productId;
  final String productUnitId;
  final QuantityDto quantity;
  final String? originalSalesOrderLineId;
  final String? sourceExchangeLineId;
  final String? reasonCode;
  final String? conditionCode;
  final ProductSnapshotDto? exchangeProductSnapshot;
  final ProductUnitSnapshotDto? exchangeUnitSnapshot;
  final MoneyDto? exchangeUnitPrice;
}
