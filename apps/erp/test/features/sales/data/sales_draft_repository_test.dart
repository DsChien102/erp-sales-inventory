// ignore_for_file: depend_on_referenced_packages

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/sales_draft_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

import 'sales_draft_parity_expectations.dart';

class _Rpc implements SupabaseRpc {
  final calls = <(String, String, Map<String, dynamic>?)>[];
  Object? result;
  Object? error;

  @override
  Future<dynamic> call(String schema, String fn, {Map<String, dynamic>? params}) async {
    calls.add((schema, fn, params));
    final e = error;
    if (e != null) throw AppException.from(e);
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late _Rpc rpc;
  var tenantReads = 0;
  var actorReads = 0;
  late SalesDraftRepository repo;

  setUp(() {
    tenantReads = 0;
    actorReads = 0;
    rpc = _Rpc();
    repo = SalesDraftRepository(
      rpc: rpc,
      tenantId: () async {
        tenantReads++;
        return draftParityTenantId;
      },
      actorId: () async {
        actorReads++;
        return draftParityActorId;
      },
    );
  });

  test('rule_blocks_before_rpc', () async {
    await expectLater(
      repo.save(
        storeId: 's1',
        currencyCode: 'VND',
        lines: const [],
        idempotencyKey: 'k',
      ),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'CONTEXT_INVALID')),
    );
    expect(rpc.calls, isEmpty);
  });

  test('list_has_no_client_permission_check', () async {
    rpc.error = PostgrestException(message: '{"code":"PERMISSION_DENIED"}');
    await expectLater(
      repo.list(storeId: 's1'),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'NO_PERMISSION')),
    );
    expect(rpc.calls, hasLength(1));
  });

  test('tenant_actor_read_each_call', () async {
    rpc.result = samplePageJson();
    await repo.list(storeId: 's1');
    await repo.list(storeId: 's1');
    expect(tenantReads, 2);
    expect(actorReads, 2);
  });

  test('restore_omits_expected_version_when_null', () async {
    rpc.result = sampleRestoreJson();
    await repo.getForRestore(draftId: draftParityDraftId, storeId: draftParityStoreId);
    expect(rpc.calls.single.$3!.containsKey('p_expected_version'), isFalse);
    expect(rpc.calls.single.$3, equals(expectedRestoreParamsNoVersion));
  });

  test('list_default_page_size_25', () async {
    rpc.result = samplePageJson();
    await repo.list(storeId: 's1');
    expect(rpc.calls.single.$3!['p_page_size'], 25);
    expect(rpc.calls.single.$3!['p_cursor'], isNull);
  });
}
