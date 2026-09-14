import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/customer_snapshot_dto.dart';
import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_order_draft_dto.dart';
import '../../../shared/sales_order_draft_line_input.dart';

@RequiresPermission(SalesPermissions.createDraft)
@RequiresTenant()
final class SaveSalesOrderDraftCommand extends SalesMutationContract<SalesOrderDraftDto>
    implements ICommand<SalesOrderDraftDto>, ITenantScopedCommand {
  SaveSalesOrderDraftCommand({
    super.id,
    super.tenantId,
    super.actorId,
    required this.storeId,
    this.customer,
    required this.currencyCode,
    this.orderNote,
    this.pricingPreviewToken,
    this.needsRevalidation = false,
    required List<SalesOrderDraftLineInput> lines,
    required super.idempotencyKey,
    super.payloadHash,
    super.correlationId,
    super.causationId,
  }) : lines = List.unmodifiable(lines);

  final String storeId;
  final CustomerSnapshotDto? customer;
  final String currencyCode;
  final String? orderNote;
  final String? pricingPreviewToken;
  final bool needsRevalidation;
  final List<SalesOrderDraftLineInput> lines;

  SaveSalesOrderDraftCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => SaveSalesOrderDraftCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    storeId: storeId,
    customer: customer,
    currencyCode: currencyCode,
    orderNote: orderNote,
    pricingPreviewToken: pricingPreviewToken,
    needsRevalidation: needsRevalidation,
    lines: lines,
    idempotencyKey: idempotencyKey,
    payloadHash: payloadHash,
    correlationId: correlationId,
    causationId: causationId,
  );
}
