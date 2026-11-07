import 'sales_contract_enums.dart';

final class SalesOrderCancellationResultDto {
  const SalesOrderCancellationResultDto({
    required this.cancellationId,
    required this.salesOrderId,
    required this.salesOrderVersion,
    required this.status,
  });

  final String cancellationId;
  final String salesOrderId;
  final int salesOrderVersion;
  final SalesOrderCancellationStatus status;
}
