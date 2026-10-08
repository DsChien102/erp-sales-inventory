import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/iam/data/audit_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRpc extends Mock implements SupabaseRpc {}

void main() {
  test('search calls search_tenant_audit_logs_v2 with event codes', () async {
    final rpc = _MockRpc();
    Map<String, dynamic>? captured;
    when(
      () => rpc.call(
        any(),
        any(),
        params: any(named: 'params'),
      ),
    ).thenAnswer((invocation) async {
      captured = Map<String, dynamic>.from(
        invocation.namedArguments[#params] as Map,
      );
      return {
        'items': <Object?>[],
        'total_count': 0,
        'next_cursor': null,
      };
    });

    final repository = AuditLogRepository(
      rpc: rpc,
      tenantId: () async => 'org-1',
    );
    final from = DateTime.utc(2026, 8, 1);
    final to = DateTime.utc(2026, 8, 31);

    await repository.search(
      from: from,
      to: to,
      query: null,
      result: 'success',
      eventCategory: 'member',
      subjectType: 'membership',
      eventCodes: const ['iam.membership.deactivated'],
      cursor: null,
    );

    expect(captured, isNotNull);
    final params = captured!;
    verify(
      () => rpc.call(
        'iam',
        'search_tenant_audit_logs_v2',
        params: any(named: 'params'),
      ),
    ).called(1);
    expect(params.keys, [
      'p_tenant_id',
      'p_from',
      'p_to',
      'p_query',
      'p_result',
      'p_event_category',
      'p_subject_type',
      'p_event_codes',
      'p_cursor',
      'p_page_size',
    ]);
    expect(params['p_tenant_id'], 'org-1');
    expect(params['p_event_codes'], ['iam.membership.deactivated']);
    expect(params['p_event_category'], 'member');
    expect(params['p_page_size'], 20);
  });
}
