import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/return_exchange_draft_dto.dart';
import '../../../shared/return_exchange_line_input.dart';
import '../../../shared/sales_contract_base.dart';

/// Technical in-session mutate of a return/exchange technical draft.
///
/// Phase 1: not a user-facing "save draft" / list-restore capability (see S31).
@RequiresPermission(SalesPermissions.updateReturnExchange)
@RequiresTenant()
final class UpdateReturnExchangeCommand extends SalesMutationContract<ReturnExchangeDraftDto> {
  UpdateReturnExchangeCommand({
    super.id,
    super.tenantId,
    super.actorId,
    required this.returnExchangeId,
    required List<ReturnExchangeLineInput> lines,
    required super.idempotencyKey,
    required super.payloadHash,
    required super.correlationId,
    super.causationId,
    required int expectedVersion,
  }) : lines = List.unmodifiable(lines),
       super(expectedSourceVersion: expectedVersion);

  final String returnExchangeId;
  final List<ReturnExchangeLineInput> lines;
  int get expectedVersion => expectedSourceVersion!;

  UpdateReturnExchangeCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => UpdateReturnExchangeCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    returnExchangeId: returnExchangeId,
    lines: lines,
    idempotencyKey: idempotencyKey,
    payloadHash: payloadHash!,
    correlationId: correlationId!,
    causationId: causationId,
    expectedVersion: expectedVersion,
  );
}
