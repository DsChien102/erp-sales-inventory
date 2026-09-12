import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_order_cancellation_result_dto.dart';

/// Internal step dispatched only by the cancellation orchestration handler.
///
/// The public contract is [ConfirmSalesOrderCancellationCommand]; this command
/// is intentionally absent from the public application barrel.
final class CancelSalesOrderCommand extends SalesMutationContract<SalesOrderCancellationResultDto> {
  CancelSalesOrderCommand({
    super.id,
    super.tenantId,
    super.actorId,
    required this.cancellationId,
    required this.salesOrderId,
    required super.idempotencyKey,
    required int expectedVersion,
    super.payloadHash,
    super.correlationId,
    super.causationId,
  }) : super(expectedSourceVersion: expectedVersion);

  final String cancellationId;
  final String salesOrderId;

  @override
  String toString() => 'CancelSalesOrderCommand($cancellationId)';
}
