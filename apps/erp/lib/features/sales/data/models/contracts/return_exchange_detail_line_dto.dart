import 'money_dto.dart';
import 'product_snapshot_dto.dart';
import 'product_unit_snapshot_dto.dart';
import 'quantity_dto.dart';
import 'sales_contract_enums.dart';

final class ReturnExchangeDetailLineDto {
  const ReturnExchangeDetailLineDto({
    this.lineId,
    required this.kind,
    required this.product,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.originalSalesOrderLineId,
    this.sourceExchangeLineId,
    this.reasonCode,
    this.conditionCode,
  });

  final String? lineId;
  final ReturnExchangeLineKind kind;
  final ProductSnapshotDto product;
  final ProductUnitSnapshotDto unit;
  final QuantityDto quantity;
  final MoneyDto unitPrice;
  final MoneyDto lineTotal;
  final String? originalSalesOrderLineId;
  final String? sourceExchangeLineId;
  final String? reasonCode;
  final String? conditionCode;
}
