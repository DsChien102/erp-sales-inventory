
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/models/sales_record_payment.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/data/sales_payment_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';
import 'package:erp/features/sales/data/models.dart';

import 'sales_checkout_parity_expectations.dart';

class _Rpc implements SupabaseRpc {
  int calls = 0;
  Object? result;
  Object? error;
  String? lastSchema;
  String? lastFn;
  Map<String, dynamic>? lastParams;

  @override
  Future<dynamic> call(String schema, String fn, {Map<String, dynamic>? params}) async {
    calls++;
    lastSchema = schema;
    lastFn = fn;
    lastParams = params;
    final e = error;
    if (e != null) throw e is AppException ? e : AppException.from(e);
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late _Rpc rpc;
  var reads = 0;
  late SalesPaymentRepository payment;
  late SalesOrderRepository order;

  setUp(() {
    reads = 0;
    rpc = _Rpc();
    Future<String> tenant() async {
      reads++;
      return checkoutTenantId;
    }

    payment = SalesPaymentRepository(rpc: rpc, tenantId: tenant, actorId: () async => 'u');
    order = SalesOrderRepository(rpc: rpc, tenantId: tenant, actorId: () async => 'u');
  });

  test('tenant_actor_read_each_call', () async {
    rpc.result = settlementJson();
    await payment.getSettlement(salesOrderId: 'o');
    await payment.getSettlement(salesOrderId: 'o');
    expect(reads, 2);
    rpc.result = orderResultJson();
    await order.get(salesOrderId: 'o');
    expect(reads, 3);
  });

  test('no_client_permission_check', () async {
    rpc.error = PostgrestException(message: '{"code":"PERMISSION_DENIED"}');
    await expectLater(
      payment.getSummary(salesOrderId: 'o'),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'NO_PERMISSION')),
    );
    await expectLater(
      order.get(salesOrderId: 'o'),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'NO_PERMISSION')),
    );
    expect(rpc.calls, 2);
  });

  test('malformed_json_is_system_error', () async {
    rpc.result = {'status': 'weird'};
    await expectLater(
      payment.getSummary(salesOrderId: 'o'),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'SYSTEM_ERROR')),
    );
  });

  test('not_found_kept', () async {
    rpc.error = PostgrestException(message: '{"code":"NOT_FOUND","message":"x"}');
    await expectLater(
      order.get(salesOrderId: 'o'),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'NOT_FOUND')),
    );
  });

  group('recordPayment', () {
    test('record_payment_params', () async {
      rpc.result = {
        'transactionId': 'tx-1',
        'outstandingMinor': 200000,
        'paymentStatus': 'partiallyPaid',
        'version': 2,
      };

      final req = const SalesRecordPaymentRequest(
        storeId: 'store-1',
        salesOrderId: 'order-1',
        amountMinor: 400000,
        method: SalesPaymentMethod.manualBankTransfer,
        externalReference: 'TXREF123',
        idempotencyKey: 'idem-1',
        payloadHash: 'hash-1',
        correlationId: 'corr-1',
      );

      await payment.recordPayment(req);

      expect(rpc.lastSchema, 'sales');
      expect(rpc.lastFn, 'record_sales_payment');
      final params = rpc.lastParams!;
      expect(params.length, 12);
      expect(params['p_tenant_id'], checkoutTenantId);
      expect(params['p_actor_id'], 'u');
      expect(params['p_store_id'], 'store-1');
      expect(params['p_sales_order_id'], 'order-1');
      expect(params['p_amount_minor'], 400000);
      expect(params['p_payment_method_code'], 'manualBankTransfer');
      expect(params['p_idempotency_key'], 'idem-1');
      expect(params['p_payload_hash'], 'hash-1');
      expect(params['p_source_context'], 'additional_collection');
      expect(params.containsKey('p_payment_method_snapshot'), isTrue);
      expect(params['p_payment_method_snapshot'], isNull);
      expect(params['p_external_reference'], 'TXREF123');
      expect(params['p_correlation_id'], 'corr-1');
    });

    test('record_payment_null_reference_keeps_key', () async {
      rpc.result = {
        'transactionId': 'tx-1',
        'outstandingMinor': 0,
        'paymentStatus': 'paid',
        'version': 2,
      };

      final req = const SalesRecordPaymentRequest(
        storeId: 'store-1',
        salesOrderId: 'order-1',
        amountMinor: 600000,
        method: SalesPaymentMethod.cash,
        externalReference: null,
        idempotencyKey: 'idem-2',
        payloadHash: 'hash-2',
        correlationId: 'corr-2',
      );

      await payment.recordPayment(req);

      final params = rpc.lastParams!;
      expect(params.containsKey('p_external_reference'), isTrue);
      expect(params['p_external_reference'], isNull);
      expect(params['p_payment_method_code'], 'cash');
    });

    test('record_payment_parses_result', () async {
      rpc.result = {
        'transactionId': 'tx-paid-1',
        'outstandingMinor': 0,
        'paymentStatus': 'paid',
        'version': 4,
      };

      final result = await payment.recordPayment(
        const SalesRecordPaymentRequest(
          storeId: 'store-1',
          salesOrderId: 'order-1',
          amountMinor: 600000,
          method: SalesPaymentMethod.cash,
          idempotencyKey: 'idem-3',
          payloadHash: 'hash-3',
          correlationId: 'corr-3',
        ),
      );

      expect(result.transactionId, 'tx-paid-1');
      expect(result.outstandingMinor, 0);
      expect(result.paymentStatus, 'paid');
      expect(result.version, 4);
    });

    test('record_payment_permission_denied_is_no_permission', () async {
      rpc.error = PostgrestException(message: '{"code":"PERMISSION_DENIED"}');
      await expectLater(
        payment.recordPayment(
          const SalesRecordPaymentRequest(
            storeId: 'store-1',
            salesOrderId: 'order-1',
            amountMinor: 600000,
            method: SalesPaymentMethod.cash,
            idempotencyKey: 'idem-4',
            payloadHash: 'hash-4',
            correlationId: 'corr-4',
          ),
        ),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'NO_PERMISSION')),
      );
    });

    test('record_payment_overpayment_not_allowed_kept', () async {
      rpc.error = PostgrestException(
        message: '{"code":"OVERPAYMENT_NOT_ALLOWED","message":"exceeded"}',
      );
      await expectLater(
        payment.recordPayment(
          const SalesRecordPaymentRequest(
            storeId: 'store-1',
            salesOrderId: 'order-1',
            amountMinor: 600000,
            method: SalesPaymentMethod.cash,
            idempotencyKey: 'idem-5',
            payloadHash: 'hash-5',
            correlationId: 'corr-5',
          ),
        ),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'OVERPAYMENT_NOT_ALLOWED')),
      );
    });

    test('record_payment_weird_error_is_system_error', () async {
      rpc.error = PostgrestException(message: '{"code":"WEIRD"}');
      await expectLater(
        payment.recordPayment(
          const SalesRecordPaymentRequest(
            storeId: 'store-1',
            salesOrderId: 'order-1',
            amountMinor: 600000,
            method: SalesPaymentMethod.cash,
            idempotencyKey: 'idem-6',
            payloadHash: 'hash-6',
            correlationId: 'corr-6',
          ),
        ),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'SYSTEM_ERROR')),
      );
    });

    test('record_payment_malformed_json_is_system_error', () async {
      rpc.result = {'unexpected': 'shape'};
      await expectLater(
        payment.recordPayment(
          const SalesRecordPaymentRequest(
            storeId: 'store-1',
            salesOrderId: 'order-1',
            amountMinor: 600000,
            method: SalesPaymentMethod.cash,
            idempotencyKey: 'idem-7',
            payloadHash: 'hash-7',
            correlationId: 'corr-7',
          ),
        ),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'SYSTEM_ERROR')),
      );
    });
  });
}
