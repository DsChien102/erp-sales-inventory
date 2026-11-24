import 'money_dto.dart';
import 'sales_contract_enums.dart';

final class SalesOrderDto {
  const SalesOrderDto({
    required this.salesOrderId,
    required this.orderNumber,
    required this.version,
    required this.lifecycleStatus,
    required this.lockStatus,
    required this.total,
  });

  final String salesOrderId;
  final String orderNumber;
  final int version;
  final SalesOrderLifecycleStatus lifecycleStatus;
  final SalesOrderLockStatus lockStatus;
  final MoneyDto total;
}
