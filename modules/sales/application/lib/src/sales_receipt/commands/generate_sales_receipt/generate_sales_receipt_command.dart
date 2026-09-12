import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_receipt_dto.dart';

@RequiresPermission(SalesPermissions.generateReceipt)
@RequiresTenant()
final class GenerateSalesReceiptCommand extends SalesMutationContract<SalesReceiptDto> {
  GenerateSalesReceiptCommand({
    super.id,
    super.tenantId,
    super.actorId,
    required this.salesOrderId,
    required super.idempotencyKey,
    super.payloadHash,
    super.correlationId,
    super.causationId,
    int? expectedVersion,
  }) : super(expectedSourceVersion: expectedVersion);

  final String salesOrderId;
  int? get expectedVersion => expectedSourceVersion;

  GenerateSalesReceiptCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => GenerateSalesReceiptCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    salesOrderId: salesOrderId,
    idempotencyKey: idempotencyKey,
    payloadHash: payloadHash,
    correlationId: correlationId,
    causationId: causationId,
    expectedVersion: expectedVersion,
  );
}
