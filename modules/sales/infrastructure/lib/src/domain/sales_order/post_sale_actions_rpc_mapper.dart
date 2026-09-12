import 'package:vet45_sales_application/application.dart';

/// Maps S21 available-actions queries to/from the `sales.*`
/// RPC wire shape. Params snake_case; result envelopes camelCase.
///
/// Return/exchange precheck moved to [IReturnExchangeReadGateway] (Group I).
abstract final class PostSaleActionsRpcMapper {
  static Map<String, dynamic> availableActionsParams(
    GetAvailablePostSaleActionsQuery query,
  ) => _orderScoped(
    query.id,
    query.tenantId,
    query.actorId,
    query.salesOrderId,
    query.expectedSourceVersion,
  );

  static AvailablePostSaleActionsDto availableActionsFromJson(Map<String, dynamic> json) {
    return AvailablePostSaleActionsDto(
      canCancel: json['canCancel'] as bool? ?? false,
      canReturnExchange: json['canReturnExchange'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> _orderScoped(
    String id,
    String tenantId,
    String actorId,
    String salesOrderId,
    int? expectedSourceVersion,
  ) {
    return <String, dynamic>{
      'query_id': id,
      'tenant_id': tenantId,
      'actor_id': actorId,
      'sales_order_id': salesOrderId,
      'expected_source_version': expectedSourceVersion,
    };
  }
}
