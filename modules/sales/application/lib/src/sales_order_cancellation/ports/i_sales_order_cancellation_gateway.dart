import '../commands/confirm_sales_order_cancellation/confirm_sales_order_cancellation_command.dart';
import '../queries/get_sales_order_cancellation/get_sales_order_cancellation_query.dart';
import '../queries/list_sales_order_cancellation_reasons/list_sales_order_cancellation_reasons_query.dart';
import '../queries/precheck_sales_order_cancellation/precheck_sales_order_cancellation_query.dart';
import '../../shared/cancellation_precheck_dto.dart';
import '../../shared/cancellation_reason_policy_dto.dart';
import '../../shared/sales_order_cancellation_detail_dto.dart';
import '../../shared/sales_order_cancellation_result_dto.dart';

abstract interface class ISalesOrderCancellationGateway {
  Future<CancellationPrecheckDto> precheck(
    PrecheckSalesOrderCancellationQuery query,
  );
  Future<SalesOrderCancellationResultDto> confirm(
    ConfirmSalesOrderCancellationCommand command,
  );
  Future<SalesOrderCancellationDetailDto> getDetail(
    GetSalesOrderCancellationQuery query,
  );
  Future<List<CancellationReasonPolicyDto>> listReasons(
    ListSalesOrderCancellationReasonsQuery query,
  );
}
