import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/mappers/sales_receipt_json.dart';
import 'package:erp/features/sales/data/sales_receipt_errors.dart';
import 'package:uuid/uuid.dart';
import 'package:vet45_sales_application/application.dart';

/// RPC phiếu bán hàng của schema `sales` (generate / get / getOriginal / recordPrinted / recordShared).
class SalesReceiptRepository {
  SalesReceiptRepository({
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

  Future<SalesReceiptDto> generate({
    required String salesOrderId,
    required int expectedVersion,
  }) => _guard(() async {
    final tid = await _tenantId();
    final raw = await _rpc.call(
      'sales',
      'generate_sales_receipt',
      params: SalesReceiptJson.generateParams(
        commandId: _newId(),
        tenantId: tid,
        actorId: await _actorId(),
        salesOrderId: salesOrderId,
        idempotencyKey: 'sales-receipt:$tid:$salesOrderId:v$expectedVersion',
        correlationId: _newId(),
        expectedSourceVersion: expectedVersion,
      ),
    );
    return SalesReceiptJson.salesReceiptFromJson(_asMap(raw));
  });

  Future<SalesReceiptDto> get({
    required String receiptId,
    int? expectedSourceVersion,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'get_sales_receipt',
      params: SalesReceiptJson.getReceiptParams(
        queryId: _newId(),
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        receiptId: receiptId,
        expectedSourceVersion: expectedSourceVersion,
      ),
    );
    return SalesReceiptJson.salesReceiptFromJson(_asMap(raw));
  });

  Future<SalesReceiptDocumentDto> getOriginal({
    required String salesOrderId,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'get_sales_order_original_receipt',
      params: SalesReceiptJson.originalReceiptParams(
        queryId: _newId(),
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        salesOrderId: salesOrderId,
      ),
    );
    return SalesReceiptJson.documentFromJson(_asMap(raw));
  });

  Future<SalesReceiptDto> recordPrinted({
    required String receiptId,
    required String commandId,
    required String idempotencyKey,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'record_sales_receipt_activity',
      params: SalesReceiptJson.printedParams(
        commandId: commandId,
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        receiptId: receiptId,
        idempotencyKey: idempotencyKey,
        correlationId: _newId(),
      ),
    );
    return SalesReceiptJson.salesReceiptFromJson(_asMap(raw));
  });

  Future<SalesReceiptDto> recordShared({
    required String receiptId,
    required String commandId,
    required String idempotencyKey,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'record_sales_receipt_activity',
      params: SalesReceiptJson.sharedParams(
        commandId: commandId,
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        receiptId: receiptId,
        idempotencyKey: idempotencyKey,
        correlationId: _newId(),
      ),
    );
    return SalesReceiptJson.salesReceiptFromJson(_asMap(raw));
  });

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on Object catch (error) {
      throw salesReceiptException(error);
    }
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map) return raw.cast<String, dynamic>();
    throw FormatException('Expected JSON object, got $raw.');
  }
}
