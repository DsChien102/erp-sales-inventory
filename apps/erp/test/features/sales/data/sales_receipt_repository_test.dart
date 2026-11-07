// ignore_for_file: depend_on_referenced_packages

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/sales_receipt_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

import 'sales_order_inquiry_parity_expectations.dart';

class _Rpc implements SupabaseRpc {
  int calls = 0;
  Object? result;
  Object? error;
  Map<String, dynamic>? lastParams;

  @override
  Future<dynamic> call(String schema, String fn, {Map<String, dynamic>? params}) async {
    calls++;
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
  late SalesReceiptRepository repository;

  setUp(() {
    reads = 0;
    rpc = _Rpc();
    Future<String> tenant() async {
      reads++;
      return inquiryTenantId;
    }

    repository = SalesReceiptRepository(
      rpc: rpc,
      tenantId: tenant,
      actorId: () async => inquiryActorId,
      newId: () => inquiryQueryId,
    );
  });

  test('generate_idempotency_key_unchanged', () async {
    rpc.result = sampleReceiptJson();
    await repository.generate(salesOrderId: inquiryOrderId, expectedVersion: 3);
    expect(
      rpc.lastParams!['p_idempotency_key'],
      'sales-receipt:$inquiryTenantId:$inquiryOrderId:v3',
    );
  });

  test('record_printed_passes_command_id_and_key', () async {
    rpc.result = sampleReceiptJson();
    await repository.recordPrinted(
      receiptId: inquiryReceiptId,
      commandId: 'cmd-9',
      idempotencyKey: 'k-9',
    );
    expect(rpc.lastParams!['p_command_id'], 'cmd-9');
    expect(rpc.lastParams!['p_idempotency_key'], 'k-9');
    expect(rpc.lastParams!['p_activity_type'], 'printed');
    expect(rpc.lastParams!.containsKey('p_expected_source_version'), isTrue);
    expect(rpc.lastParams!['p_expected_source_version'], isNull);
  });

  test('original_receipt_parses_unwrapped_document', () async {
    rpc.result = sampleOriginalDocumentJson();
    final document = await repository.getOriginal(salesOrderId: inquiryOrderId);
    expect(document.receiptNumber, 'PBH-20260812-0129');
    expect(document.lines, hasLength(1));
  });

  test('tenant_actor_read_each_call', () async {
    rpc.result = sampleReceiptJson();
    await repository.generate(salesOrderId: inquiryOrderId, expectedVersion: 1);
    await repository.get(receiptId: inquiryReceiptId);
    expect(reads, 2);
  });

  test('no_client_permission_check', () async {
    rpc.error = const PostgrestException(message: '{"code":"PERMISSION_DENIED"}');
    await expectLater(
      repository.get(receiptId: inquiryReceiptId),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'NO_PERMISSION')),
    );
    expect(rpc.calls, 1);
  });
}
