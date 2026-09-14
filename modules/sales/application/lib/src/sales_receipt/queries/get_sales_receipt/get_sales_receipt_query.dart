import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_receipt_dto.dart';

@RequiresPermission(SalesPermissions.viewReceipt)
@RequiresTenant()
final class GetSalesReceiptQuery extends SalesReadContract<SalesReceiptDto> {
  GetSalesReceiptQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.receiptId,
    this.expectedSourceVersion,
  });

  final String receiptId;
  final int? expectedSourceVersion;

  GetSalesReceiptQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => GetSalesReceiptQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    receiptId: receiptId,
    expectedSourceVersion: expectedSourceVersion,
  );
}
