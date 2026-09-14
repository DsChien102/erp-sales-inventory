import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/return_exchange_result_dto.dart';

/// Discard session / cancel technical draft (Phase 1 S31).
///
/// Idempotent. Releases reservation per policy. Not a user draft-list delete UX.
@RequiresPermission(SalesPermissions.cancelReturnExchange)
@RequiresTenant()
final class CancelReturnExchangeCommand extends SalesMutationContract<ReturnExchangeResultDto> {
  CancelReturnExchangeCommand({
    super.id,
    super.tenantId,
    super.actorId,
    required this.returnExchangeId,
    required super.idempotencyKey,
    super.payloadHash,
    super.correlationId,
    super.causationId,
    int? expectedVersion,
  }) : super(expectedSourceVersion: expectedVersion);

  final String returnExchangeId;
  int? get expectedVersion => expectedSourceVersion;

  CancelReturnExchangeCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => CancelReturnExchangeCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    returnExchangeId: returnExchangeId,
    idempotencyKey: idempotencyKey,
    payloadHash: payloadHash,
    correlationId: correlationId,
    causationId: causationId,
    expectedVersion: expectedVersion,
  );
}
