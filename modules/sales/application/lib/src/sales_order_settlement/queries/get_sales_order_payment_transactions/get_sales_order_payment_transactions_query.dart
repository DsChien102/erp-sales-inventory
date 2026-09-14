import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_payment_transactions_dto.dart';

@RequiresPermission(SalesPermissions.viewPayment)
@RequiresTenant()
final class GetSalesOrderPaymentTransactionsQuery
    extends SalesReadContract<SalesPaymentTransactionsDto> {
  GetSalesOrderPaymentTransactionsQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.salesOrderId,
    this.expectedSourceVersion,
    this.cursor,
    this.pageSize = 25,
  });

  final String salesOrderId;
  final int? expectedSourceVersion;
  final String? cursor;
  final int pageSize;

  GetSalesOrderPaymentTransactionsQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => GetSalesOrderPaymentTransactionsQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    salesOrderId: salesOrderId,
    expectedSourceVersion: expectedSourceVersion,
    cursor: cursor,
    pageSize: pageSize,
  );
}
