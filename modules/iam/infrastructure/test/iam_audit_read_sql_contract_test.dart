import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    sql = File(
      '${_findRepoRoot().path}/supabase/migrations/20260811013_iam_platform_audit_read.sql',
    ).readAsStringSync();
  });

  group('tenant audit read', () {
    test('tenant queries read canonical iam.audit_logs table', () {
      expect(sql, contains('from iam.audit_logs a'));
      expect(sql, isNot(contains('from iam.platform_audit_logs')));
    });

    test('search is cursor-paginated with default 20 / max 100', () {
      expect(
        sql,
        contains('least(greatest(coalesce(p_page_size, 20), 1), 100)'),
      );
      expect(sql, contains("split_part(p_cursor, '|', 1)::timestamptz"));
      expect(sql, contains('order by a.occurred_at desc, a.id desc'));
    });

    test('requires active membership and audit permission', () {
      expect(sql, contains("and m.status = 'active'"));
      expect(sql, contains("iam.has_permission(p_tenant_id, 'tenant.audit.view')"));
    });

    test('detail filters both tenant_id and audit_log_id (non-enumerating)', () {
      expect(sql, contains('where a.id = p_audit_log_id'));
      expect(sql, contains('and a.tenant_id = p_tenant_id'));
      expect(sql, contains("raise exception 'RESOURCE_NOT_FOUND'"));
    });

    test('surfaces actor_unavailable when actor was deleted', () {
      expect(sql, contains('actor_unavailable'));
      expect(sql, contains('not exists (select 1 from auth.users au'));
    });

    test('does not reconstruct redacted values on read', () {
      // Read returns stored before/after states directly, no un-redaction.
      expect(sql, contains("'before_state', v_row.before_state"));
      expect(sql, contains("'after_state', v_row.after_state"));
    });

    test('search accepts optional p_event_code filter', () {
      expect(sql, contains('p_event_code text default null'));
      expect(sql, contains('p_event_code is null or a.event_code = p_event_code'));
    });
  });

  group('S16 platform audit converged onto iam.audit_logs', () {
    test('search reads iam.audit_logs with platform scope', () {
      expect(sql, contains('from iam.audit_logs a'));
      expect(sql, contains("where a.scope = 'platform'"));
    });

    test('detail reads iam.audit_logs and not the interim table', () {
      final detailStart = sql.indexOf('function iam.get_platform_audit_log');
      final detailEnd = sql.indexOf(r'$$;', detailStart);
      final body = sql.substring(detailStart, detailEnd);
      expect(body, contains('from iam.audit_logs a'));
      expect(body, isNot(contains('from iam.platform_audit_logs')));
    });
  });

  test('tenant audit RPCs granted to authenticated only', () {
    expect(
      sql,
      contains(
        'grant execute on function iam.search_tenant_audit_logs(uuid, timestamptz, timestamptz, text, text, text, text, text, integer) to authenticated',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function iam.get_tenant_audit_log(uuid, uuid) to authenticated',
      ),
    );
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
