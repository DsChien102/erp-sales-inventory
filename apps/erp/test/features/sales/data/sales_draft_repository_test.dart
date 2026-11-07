
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/mappers/sales_draft_json.dart';
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

  test('list_sends_search_and_created_by', () async {
    rpc.result = samplePageJson();
    await repo.list(
      storeId: 's1',
      pageSize: 25,
      search: 'an',
      createdByUserId: 'user-1',
    );
    expect(rpc.calls.single.$3!['p_page_size'], 25);
    expect(rpc.calls.single.$3!['p_search'], 'an');
    expect(rpc.calls.single.$3!['p_created_by'], 'user-1');
  });

  test('list_null_filters_keep_keys', () async {
    rpc.result = samplePageJson();
    await repo.list(storeId: 's1');
    expect(rpc.calls.single.$3!.containsKey('p_search'), isTrue);
    expect(rpc.calls.single.$3!['p_search'], isNull);
    expect(rpc.calls.single.$3!.containsKey('p_created_by'), isTrue);
    expect(rpc.calls.single.$3!['p_created_by'], isNull);
  });

  test('page_reads_created_by_name', () {
    final jsonWithName = {
      'items': [sampleDraftJson()..['created_by_name'] = 'Lan'],
      'has_more': false,
      'total_count': 1,
    };
    final page1 = SalesDraftJson.page(jsonWithName);
    expect(page1.items.single.createdByName, 'Lan');

    final jsonWithoutName = {
      'items': [sampleDraftJson()..remove('created_by_name')],
      'has_more': false,
      'total_count': 1,
    };
    final page2 = SalesDraftJson.page(jsonWithoutName);
    expect(page2.items.single.createdByName, isNull);
  });

  test('page_reads_total_count', () {
    final json = {
      'items': [sampleDraftJson()],
      'has_more': false,
      'total_count': 25,
    };
    final page = SalesDraftJson.page(json);
    expect(page.totalCount, 25);

    expect(
      () => SalesDraftJson.page({'items': [], 'has_more': false}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => SalesDraftJson.page({'items': [], 'has_more': false, 'total_count': 'not-an-int'}),
      throwsA(isA<FormatException>()),
    );
  });
}
