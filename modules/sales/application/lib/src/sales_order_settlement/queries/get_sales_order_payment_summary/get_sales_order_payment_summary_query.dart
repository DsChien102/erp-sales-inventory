import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_order_payment_summary_dto.dart';

@RequiresPermission(SalesPermissions.viewPayment)
@RequiresTenant()
final class GetSalesOrderPaymentSummaryQuery
    extends SalesReadContract<SalesOrderPaymentSummaryDto> {
  GetSalesOrderPaymentSummaryQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.salesOrderId,
    this.expectedSourceVersion,
  });

  final String salesOrderId;
  final int? expectedSourceVersion;

  GetSalesOrderPaymentSummaryQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => GetSalesOrderPaymentSummaryQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    salesOrderId: salesOrderId,
    expectedSourceVersion: expectedSourceVersion,
  );
}
