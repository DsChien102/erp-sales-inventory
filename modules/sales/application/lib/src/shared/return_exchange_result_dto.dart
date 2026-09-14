import 'sales_contract_enums.dart';

final class ReturnExchangeResultDto {
  const ReturnExchangeResultDto({
    required this.returnExchangeId,
    required this.salesOrderId,
    required this.version,
    required this.status,
  });

  final String returnExchangeId;
  final String salesOrderId;
  final int version;
  final ReturnExchangeStatus status;
}
