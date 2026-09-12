import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/customer_snapshot_dto.dart';
import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_order_draft_dto.dart';
import '../../../shared/sales_order_draft_line_input.dart';

@RequiresPermission(SalesPermissions.updateDraft)
@RequiresTenant()
final class UpdateSalesOrderDraftCommand extends SalesMutationContract<SalesOrderDraftDto>
    implements ICommand<SalesOrderDraftDto>, ITenantScopedCommand {
  UpdateSalesOrderDraftCommand({
    super.id,
    super.tenantId,
    super.actorId,
    required this.draftId,
    required this.storeId,
    this.customer,
    required this.currencyCode,
    this.orderNote,
    this.pricingPreviewToken,
    this.needsRevalidation = false,
    required List<SalesOrderDraftLineInput> lines,
    required super.idempotencyKey,
    required int expectedVersion,
    super.payloadHash,
    super.correlationId,
    super.causationId,
  }) : lines = List.unmodifiable(lines),
       super(expectedSourceVersion: expectedVersion);

  final String draftId;
  final String storeId;
  final CustomerSnapshotDto? customer;
  final String currencyCode;
  final String? orderNote;
  final String? pricingPreviewToken;
  final bool needsRevalidation;
  final List<SalesOrderDraftLineInput> lines;

  int get expectedVersion => expectedSourceVersion!;

  UpdateSalesOrderDraftCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => UpdateSalesOrderDraftCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    draftId: draftId,
    storeId: storeId,
    customer: customer,
    currencyCode: currencyCode,
    orderNote: orderNote,
    pricingPreviewToken: pricingPreviewToken,
    needsRevalidation: needsRevalidation,
    lines: lines,
    idempotencyKey: idempotencyKey,
    expectedVersion: expectedVersion,
    payloadHash: payloadHash,
    correlationId: correlationId,
    causationId: causationId,
  );
}
