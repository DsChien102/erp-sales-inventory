import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/money_dto.dart';
import '../../../shared/return_exchange_settlement_result_dto.dart';
import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_contract_enums.dart';

@RequiresPermission(SalesPermissions.refundPayment)
@RequiresTenant()
final class RecordSalesRefundCommand
    extends SalesMutationContract<ReturnExchangeSettlementResultDto> {
  RecordSalesRefundCommand({
    super.id,
    super.tenantId,
    super.actorId,
    required this.returnExchangeId,
    required this.method,
    required this.amount,
    this.reference,
    required super.idempotencyKey,
    required super.payloadHash,
    required super.correlationId,
    super.causationId,
    required int expectedVersion,
  }) : super(expectedSourceVersion: expectedVersion);

  final String returnExchangeId;
  final SalesPaymentMethod method;
  final MoneyDto amount;
  final String? reference;
  int get expectedVersion => expectedSourceVersion!;

  RecordSalesRefundCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => RecordSalesRefundCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    returnExchangeId: returnExchangeId,
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
