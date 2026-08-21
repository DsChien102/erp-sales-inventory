import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String draft;
  late String searchBody;
  late String detailBody;

  setUpAll(() {
    final root = _findRepoRoot();
    draft = File(
      '${root.path}/supabase/migrations/_drafts/005_iam_tenant_audit_history_v2_read.sql',
    ).readAsStringSync();
    final searchStart = draft.indexOf(
      'create or replace function iam.search_tenant_audit_logs_v2(',
    );
    final searchEnd = draft.indexOf(r'$$;', searchStart);
    final detailStart = draft.indexOf(
      'create or replace function iam.get_tenant_audit_log(',
    );
    final detailEnd = draft.indexOf(r'$$;', detailStart);
    if (searchStart < 0 || searchEnd < 0 || detailStart < 0 || detailEnd < 0) {
      throw StateError('Could not extract tenant audit read RPC bodies');
    }
    searchBody = draft.substring(searchStart, searchEnd + 3);
    detailBody = draft.substring(detailStart, detailEnd + 3);
  });

  group('iam_tenant_audit_history_v2_read draft SQL contract', () {
    test('declares correct patch header with touches', () {
      expect(draft, contains('-- Title: IAM tenant audit history V2 read RPC'));
      expect(draft, contains('-- Kind: patch'));
      expect(draft, contains('-- Intent: iam_tenant_audit_history_v2'));
      expect(
        draft,
        contains('-- Touches: iam.search_tenant_audit_logs_v2, iam.get_tenant_audit_log'),
      );
    });

    test('declares search_tenant_audit_logs_v2 with exact V2 parameters', () {
      expect(
        draft,
        contains('function iam.search_tenant_audit_logs_v2('),
      );
      expect(draft, contains('p_tenant_id uuid'));
      expect(draft, contains('p_from timestamptz'));
      expect(draft, contains('p_to timestamptz'));
      expect(draft, contains('p_query text default null'));
      expect(draft, contains('p_result text default null'));
      expect(draft, contains('p_event_category text default null'));
      expect(draft, contains('p_subject_type text default null'));
      expect(draft, contains('p_event_codes text[] default null'));
      expect(draft, contains('p_cursor text default null'));
      expect(draft, contains('p_page_size integer default 20'));
    });

    test('enforces start-inclusive, end-exclusive time range', () {
      expect(draft, contains('occurred_at >= p_from'));
      expect(draft, contains('occurred_at < p_to'));
    });

    test('implements category filter and event_codes any array match', () {
      expect(draft, contains('p_event_category is null or a.event_category = p_event_category'));
      expect(draft, contains('p_event_codes is null or a.event_code = any(p_event_codes)'));
    });

    test('computes total_count before cursor slicing and fetches limit + 1', () {
      expect(draft, contains('total_count'));
      expect(draft, contains('least(greatest(coalesce(p_page_size, 20), 1), 100)'));
      expect(draft, contains('limit v_limit + 1'));
    });

    test('cursor belongs to the last returned row, never the lookahead row', () {
      expect(draft, contains('v_last_returned_time timestamptz'));
      expect(draft, contains('v_last_returned_id uuid'));
      expect(
        draft,
        contains(
          'v_next_cursor := to_char(v_last_returned_time at time zone \'UTC\'',
        ),
      );
      expect(
        draft,
        contains("|| '|' || v_last_returned_id::text"),
      );
      expect(
        draft,
        isNot(
          contains(
            'v_next_cursor := to_char(v_row.occurred_at at time zone \'UTC\'',
          ),
        ),
      );
    });

    test('uses canonical identity and invitation schema names', () {
      expect(draft, contains('auth.users'));
      expect(draft, contains('iam.platform_user_profiles'));
      expect(draft, contains('inv.invitee_email'));
      expect(draft, contains('inv.initial_role_id'));
      expect(draft, isNot(contains('iam.platform_users')));
      expect(draft, isNot(contains('inv.email')));
      expect(draft, isNot(contains('inv.role')));
    });

    test('tenant-owned enrichment joins include tenant ownership predicates', () {
      for (final body in [searchBody, detailBody]) {
        expect(body, contains('t.id = a.tenant_id'));
        expect(body, contains('inv.tenant_id = a.tenant_id'));
        expect(body, contains('sm.tenant_id = a.tenant_id'));
      }
    });

    test('detail cannot return a platform record that happens to carry the tenant id', () {
      expect(detailBody, contains("where a.id = p_audit_log_id\n    and a.scope = 'tenant'\n    and a.tenant_id = p_tenant_id"));
    });

    test('count and page search the same tenant-scoped current subject fields', () {
      for (final body in [searchBody]) {
        expect(body, contains('left join iam.memberships sm on ('));
        expect(body, contains('sm.tenant_id = a.tenant_id'));
        expect(body, contains('left join iam.platform_user_profiles sup on sup.user_id = su.id'));
        expect(body, contains('sm.role ilike'));
        expect(body, contains('t.code ilike'));
      }
    });

    test('current actor membership is deterministic and cannot duplicate rows', () {
      for (final body in [searchBody, detailBody]) {
        expect(body, contains('left join lateral ('));
        expect(body, contains('am.tenant_id = a.tenant_id'));
        expect(body, contains('am.user_id = a.actor_user_id'));
        expect(body, contains("when 'active' then 0"));
        expect(body, contains('am.updated_at desc'));
        expect(body, contains('limit 1'));
        expect(
          body,
          isNot(
            contains(
              'left join iam.memberships m on (m.tenant_id = a.tenant_id and m.user_id = a.actor_user_id)',
            ),
          ),
        );
      }
    });

    test('detail keeps before and after redaction flags independent', () {
      expect(draft, contains("f like 'before.%'"));
      expect(draft, contains("f like 'after.%'"));
      expect(draft, contains("'before_redacted', v_before_redacted"));
      expect(draft, contains("'after_redacted', v_after_redacted"));
    });

    test('surfaces display origins and nested actor/subject structures', () {
      expect(draft, contains("'actor',"));
      expect(draft, contains("'subject',"));
      expect(draft, contains("'display_origin'"));
      expect(draft, contains("'snapshot'"));
      expect(draft, contains("'current'"));
      expect(draft, contains("'system'"));
      expect(draft, contains("'unavailable'"));
    });

    test('grants execution to authenticated role only', () {
      const searchSignature =
          'iam.search_tenant_audit_logs_v2(uuid, timestamptz, timestamptz, text, text, text, text, text[], text, integer)';
      final searchRevoke = draft.indexOf(
        'revoke all on function $searchSignature from public, anon',
      );
      final searchGrant = draft.indexOf(
        'grant execute on function $searchSignature to authenticated',
      );
      expect(searchRevoke, greaterThanOrEqualTo(0));
      expect(searchGrant, greaterThan(searchRevoke));
      expect(
        draft,
        contains(
          'grant execute on function iam.search_tenant_audit_logs_v2(uuid, timestamptz, timestamptz, text, text, text, text, text[], text, integer) to authenticated',
        ),
      );
      expect(
        draft,
        contains(
          'grant execute on function iam.get_tenant_audit_log(uuid, uuid) to authenticated',
        ),
      );
    });
  });
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate Vet45 workspace root');
    }
    current = parent;
  }
  return current;
}
