import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/mappers/sales_payment_json.dart';
import 'package:erp/features/sales/data/models/sales_record_payment.dart';
import 'package:erp/features/sales/data/sales_order_read_errors.dart';
import 'package:erp/features/sales/data/sales_payment_mutation_errors.dart';
import 'package:uuid/uuid.dart';
import 'package:vet45_sales_application/application.dart';

/// 3 RPC thanh toán của schema `sales` (summary / settlement / transactions).
class SalesPaymentRepository {
  SalesPaymentRepository({
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

  Future<SalesOrderPaymentSummaryDto> getSummary({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'get_sales_order_payment_summary',
      params: SalesPaymentJson.summaryParams(
        queryId: _newId(),
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        salesOrderId: salesOrderId,
        expectedSourceVersion: expectedSourceVersion,
      ),
    );
    return SalesPaymentJson.paymentSummaryFromJson(_asMap(raw));
  });

  Future<SalesOrderSettlementDto> getSettlement({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'get_sales_order_settlement',
      params: SalesPaymentJson.settlementParams(
        queryId: _newId(),
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        salesOrderId: salesOrderId,
        expectedSourceVersion: expectedSourceVersion,
      ),
    );
    return SalesPaymentJson.settlementFromJson(_asMap(raw));
  });

  Future<SalesPaymentTransactionsDto> getTransactions({
    required String salesOrderId,
    int? expectedSourceVersion,
    String? cursor,
    int pageSize = 25,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'get_sales_order_payment_transactions',
      params: SalesPaymentJson.transactionsParams(
        queryId: _newId(),
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        salesOrderId: salesOrderId,
        expectedSourceVersion: expectedSourceVersion,
        cursor: cursor,
        pageSize: pageSize,
      ),
    );
    return SalesPaymentJson.transactionsFromJson(_asMap(raw));
  });

  Future<SalesRecordPaymentResult> recordPayment(SalesRecordPaymentRequest request) =>
      _mutationGuard(() async {
        final raw = await _rpc.call(
          'sales',
          'record_sales_payment',
          params: SalesPaymentJson.recordParams(
            tenantId: await _tenantId(),
            actorId: await _actorId(),
            request: request,
          ),
        );
        return SalesPaymentJson.recordResultFromJson(_asMap(raw));
      });

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on Object catch (error) {
      throw salesOrderReadException(error);
    }
  }

  Future<T> _mutationGuard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on Object catch (error) {
      throw salesPaymentMutationException(error);
    }
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map) return raw.cast<String, dynamic>();
    throw FormatException('Expected JSON object, got $raw.');
  }
}
