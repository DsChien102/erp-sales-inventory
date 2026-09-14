import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_receipt_dto.dart';

@RequiresPermission(SalesPermissions.archiveReceipt)
@RequiresTenant()
final class ArchiveSalesReceiptCommand extends SalesMutationContract<SalesReceiptDto> {
  ArchiveSalesReceiptCommand({
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

  ArchiveSalesReceiptCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => ArchiveSalesReceiptCommand(
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
