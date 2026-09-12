import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/return_exchange_draft_dto.dart';
import '../../../shared/return_exchange_line_input.dart';
import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_contract_enums.dart';

@RequiresPermission(SalesPermissions.createReturnExchange)
@RequiresTenant()
final class StartReturnExchangeCommand extends SalesMutationContract<ReturnExchangeDraftDto> {
  StartReturnExchangeCommand({
    super.id,
    super.tenantId,
    super.actorId,
    required this.salesOrderId,
    required this.entrySource,
    required List<ReturnExchangeLineInput> lines,
    required super.idempotencyKey,
    required super.payloadHash,
    required super.correlationId,
    super.causationId,
    required int expectedVersion,
  }) : lines = List.unmodifiable(lines),
       super(expectedSourceVersion: expectedVersion);

  final String salesOrderId;
  final ReturnExchangeEntrySource entrySource;
  final List<ReturnExchangeLineInput> lines;
  int get expectedVersion => expectedSourceVersion!;

  StartReturnExchangeCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => StartReturnExchangeCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    salesOrderId: salesOrderId,
    entrySource: entrySource,
    lines: lines,
    idempotencyKey: idempotencyKey,
    payloadHash: payloadHash!,
    correlationId: correlationId!,
    causationId: causationId,
    expectedVersion: expectedVersion,
  );
}
