import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/mappers/sales_order_get_json.dart';
import 'package:erp/features/sales/data/sales_order_read_errors.dart';
import 'package:uuid/uuid.dart';
import 'package:vet45_sales_application/application.dart';

/// RPC đọc đơn của schema `sales`. 8-A2 chỉ có `get`; 8-A3 thêm list / search / detail / timeline.
class SalesOrderRepository {
  SalesOrderRepository({
    required SupabaseRpc rpc,
    required Future<String> Function() tenantId,
    required Future<String> Function() actorId,
    String Function()? newId,
  }) : _rpc = rpc,
       _tenantId = tenantId,
       _actorId = actorId,
       _newId = newId ?? const Uuid().v4;

  final SupabaseRpc _rpc;
  final Future<String> Function() _tenantId;
  final Future<String> Function() _actorId;
  final String Function() _newId;

  Future<SalesOrderResultDto> get({required String salesOrderId}) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'get_sales_order',
      params: SalesOrderGetJson.params(
        queryId: _newId(),
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        salesOrderId: salesOrderId,
      ),
    );
    return SalesOrderGetJson.salesOrderResultFromJson(_asMap(raw));
  });

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on Object catch (error) {
      throw salesOrderReadException(error);
    }
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map) return raw.cast<String, dynamic>();
    throw FormatException('Expected JSON object, got $raw.');
  }
}
