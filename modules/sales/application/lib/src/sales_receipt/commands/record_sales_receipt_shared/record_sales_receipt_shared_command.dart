import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_receipt_dto.dart';

@RequiresPermission(SalesPermissions.shareReceipt)
@RequiresTenant()
final class RecordSalesReceiptSharedCommand extends SalesMutationContract<SalesReceiptDto> {
  RecordSalesReceiptSharedCommand({
    super.id,
    super.tenantId,
    super.actorId,
    required this.receiptId,
    required super.idempotencyKey,
    super.payloadHash,
    super.correlationId,
    super.causationId,
    int? expectedVersion,
  }) : super(expectedSourceVersion: expectedVersion);

  final String receiptId;
  int? get expectedVersion => expectedSourceVersion;

  RecordSalesReceiptSharedCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => RecordSalesReceiptSharedCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    receiptId: receiptId,
    idempotencyKey: idempotencyKey,
    payloadHash: payloadHash,
    correlationId: correlationId,
    causationId: causationId,
    expectedVersion: expectedVersion,
  );
}
