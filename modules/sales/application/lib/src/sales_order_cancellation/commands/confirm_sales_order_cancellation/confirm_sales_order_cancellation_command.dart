import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/cancellation_reason_dto.dart';
import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_order_cancellation_result_dto.dart';

@RequiresPermission(SalesPermissions.cancelOrder)
@RequiresTenant()
final class ConfirmSalesOrderCancellationCommand
    extends SalesMutationContract<SalesOrderCancellationResultDto> {
  ConfirmSalesOrderCancellationCommand({
    super.id,
    super.tenantId,
    super.actorId,
    required this.salesOrderId,
    required this.reason,
    required super.idempotencyKey,
    required super.payloadHash,
    required super.correlationId,
    super.causationId,
    required int expectedVersion,
    required this.expectedSettlementVersion,
  }) : super(expectedSourceVersion: expectedVersion);

  final String salesOrderId;
  final CancellationReasonDto reason;
  final int expectedSettlementVersion;
  int get expectedVersion => expectedSourceVersion!;

  ConfirmSalesOrderCancellationCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => ConfirmSalesOrderCancellationCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    salesOrderId: salesOrderId,
    reason: reason,
    idempotencyKey: idempotencyKey,
    payloadHash: payloadHash!,
    correlationId: correlationId!,
    causationId: causationId,
    expectedVersion: expectedVersion,
    expectedSettlementVersion: expectedSettlementVersion,
  );
}
