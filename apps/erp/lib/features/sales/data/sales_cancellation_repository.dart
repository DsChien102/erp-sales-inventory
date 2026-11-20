import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/mappers/sales_cancellation_json.dart';
import 'package:erp/features/sales/data/models/sales_cancellation_request.dart';
import 'package:erp/features/sales/data/sales_cancellation_errors.dart';
import 'package:uuid/uuid.dart';
import 'package:erp/features/sales/data/models.dart';

/// Repository xử lý tiền kiểm và huỷ đơn hàng bán (`sales.precheck_sales_order_cancellation`
/// và `sales.confirm_sales_order_cancellation`).
class SalesCancellationRepository {
  SalesCancellationRepository({
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

  Future<CancellationPrecheckDto> precheck({
    required String salesOrderId,
    required int expectedSourceVersion,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'precheck_sales_order_cancellation',
      params: SalesCancellationJson.precheckParams(
        queryId: _newId(),
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        salesOrderId: salesOrderId,
        expectedSourceVersion: expectedSourceVersion,
      ),
    );
    return SalesCancellationJson.precheckFromJson(_asMap(raw));
  });

  Future<SalesOrderCancellationResultDto> confirm(
    SalesOrderCancellationRequest request,
  ) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'confirm_sales_order_cancellation',
      params: SalesCancellationJson.confirmParams(
        request: request,
        tenantId: await _tenantId(),
        actorId: await _actorId(),
      ),
    );
    return SalesCancellationJson.resultFromJson(_asMap(raw));
  });

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on Object catch (error) {
      throw salesCancellationException(error);
    }
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map) return raw.cast<String, dynamic>();
    throw FormatException('Expected JSON object, got $raw.');
  }
}

