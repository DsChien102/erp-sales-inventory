import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/return_exchange_result_dto.dart';

@RequiresPermission(SalesPermissions.completeReturnExchange)
@RequiresTenant()
final class CompleteReturnExchangeCommand extends SalesMutationContract<ReturnExchangeResultDto> {
  CompleteReturnExchangeCommand({
    super.id,
    super.tenantId,
    super.actorId,
    required this.returnExchangeId,
    required super.idempotencyKey,
    required super.payloadHash,
    required super.correlationId,
    super.causationId,
    required int expectedVersion,
  }) : super(expectedSourceVersion: expectedVersion);

  final String returnExchangeId;
  int get expectedVersion => expectedSourceVersion!;

  CompleteReturnExchangeCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => CompleteReturnExchangeCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    returnExchangeId: returnExchangeId,
    idempotencyKey: idempotencyKey,
    payloadHash: payloadHash!,
    correlationId: correlationId!,
    causationId: causationId,
    expectedVersion: expectedVersion,
  );
}
