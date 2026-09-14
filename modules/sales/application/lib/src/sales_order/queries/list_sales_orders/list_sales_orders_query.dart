import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/paged_sales_order_list_dto.dart';
import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_order_list_filter_input.dart';

@RequiresPermission(SalesPermissions.viewOrder)
@RequiresTenant()
final class ListSalesOrdersQuery extends SalesReadContract<PagedSalesOrderListDto> {
  ListSalesOrdersQuery({
    super.id,
    super.tenantId,
    super.actorId,
    this.cursor,
    this.pageSize = 25,
    this.filter,
  });

  final String? cursor;
  final int pageSize;
  final SalesOrderListFilterInput? filter;

  ListSalesOrdersQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => ListSalesOrdersQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    cursor: cursor,
    pageSize: pageSize,
    filter: filter,
  );
}
