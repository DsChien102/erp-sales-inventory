import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_receipt_document_dto.dart';

/// As-sold receipt document for the «Đơn gốc» tab: original order lines, sale
/// totals and checkout payments. Computed on read, never persisted.
@RequiresPermission(SalesPermissions.viewReceipt)
@RequiresTenant()
final class GetSalesOrderOriginalReceiptQuery extends SalesReadContract<SalesReceiptDocumentDto> {
  GetSalesOrderOriginalReceiptQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.salesOrderId,
  });

  final String salesOrderId;

  GetSalesOrderOriginalReceiptQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => GetSalesOrderOriginalReceiptQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    salesOrderId: salesOrderId,
  );
}
