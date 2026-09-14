import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/money_dto.dart';
import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_contract_enums.dart';
import '../../../shared/sales_order_payment_summary_dto.dart';

@RequiresPermission(SalesPermissions.recordPayment)
@RequiresTenant()
final class RecordSalesPaymentCommand extends SalesMutationContract<SalesOrderPaymentSummaryDto> {
  RecordSalesPaymentCommand({
    super.id,
    super.tenantId,
    super.actorId,
    required this.salesOrderId,
    required this.method,
    required this.amount,
    this.reference,
    required super.idempotencyKey,
    required super.payloadHash,
    required super.correlationId,
    super.causationId,
    required int expectedVersion,
  }) : super(expectedSourceVersion: expectedVersion);

  final String salesOrderId;
  final SalesPaymentMethod method;
  final MoneyDto amount;
  final String? reference;
  int get expectedVersion => expectedSourceVersion!;

  RecordSalesPaymentCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => RecordSalesPaymentCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    salesOrderId: salesOrderId,
    method: method,
    amount: amount,
    reference: reference,
    idempotencyKey: idempotencyKey,
    payloadHash: payloadHash!,
    correlationId: correlationId!,
    causationId: causationId,
    expectedVersion: expectedVersion,
  );
}
