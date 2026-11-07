import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/mappers/sales_checkout_json.dart';
import 'package:erp/features/sales/data/models/sales_finalize_request.dart';
import 'package:erp/features/sales/data/sales_checkout_errors.dart';
import 'package:erp/features/sales/logic/sales_checkout_rules.dart';
import 'package:uuid/uuid.dart';
import 'package:erp/features/sales/data/models.dart';

/// 3 RPC checkout của schema `sales`. Nhận / trả kiểu của `data/models.dart` (Q1).
class SalesCheckoutRepository {
  SalesCheckoutRepository({
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

  Future<CheckoutPrecheckDto> precheck({
    required String storeId,
    String? customerId,
    required String currencyCode,
    DateTime? paymentDueDate,
    required List<CheckoutLineInput> lines,
    required List<PaymentIntentInput> paymentIntents,
    int? expectedSourceVersion,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'precheck_sales_order_checkout',
      params: SalesCheckoutJson.precheckParams(
        queryId: _newId(),
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        storeId: storeId,
        customerId: customerId,
        currencyCode: currencyCode,
        paymentDueDate: paymentDueDate,
        lines: lines,
        paymentIntents: paymentIntents,
        expectedSourceVersion: expectedSourceVersion,
      ),
    );
    return SalesCheckoutJson.precheckFromJson(_asMap(raw));
  });

  Future<CheckoutResultDto> finalize(SalesFinalizeRequest request) => _guard(() async {
    checkFinalize(
      storeId: request.storeId,
      currencyCode: request.currencyCode,
      idempotencyKey: request.idempotencyKey,
      payloadHash: request.payloadHash,
      correlationId: request.correlationId,
      lines: request.lines,
      paymentIntents: request.paymentIntents,
    );
    final raw = await _rpc.call(
      'sales',
      'finalize_sales_order',
      params: SalesCheckoutJson.finalizeParams(
        request,
        tenantId: await _tenantId(),
        actorId: await _actorId(),
      ),
    );
    return SalesCheckoutJson.checkoutResultFromJson(_asMap(raw));
  }, uncertainOnNetwork: true);

  Future<CheckoutResultDto> getResult({
    required String storeId,
    required String idempotencyKey,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'get_checkout_result',
      params: SalesCheckoutJson.statusParams(
        queryId: _newId(),
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        idempotencyKey: idempotencyKey,
        storeId: storeId,
      ),
    );
    return SalesCheckoutJson.checkoutResultFromJson(_asMap(raw));
  });

  Future<T> _guard<T>(Future<T> Function() fn, {bool uncertainOnNetwork = false}) async {
    try {
      return await fn();
    } on Object catch (error) {
      throw salesCheckoutException(error, uncertainOnNetwork: uncertainOnNetwork);
    }
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map) return raw.cast<String, dynamic>();
    throw FormatException('Expected JSON object, got $raw.');
  }
}
