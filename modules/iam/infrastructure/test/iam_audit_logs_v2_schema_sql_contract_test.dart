import 'dart:io';

import 'package:test/test.dart';

/// Locks the V2 rebuild of `iam.audit_logs` (big-bang, dev). Phase 1 = schema.
void main() {
  late String sql;
  late Directory migrations;

  setUpAll(() {
    final root = _findRepoRoot();
    migrations = Directory('${root.path}/supabase/migrations');
    sql = File(
      '${root.path}/supabase/migrations/_drafts/007_iam_audit_logs_v2_rebuild.sql',
    ).readAsStringSync();
  });

  group('audit_logs V2 schema (Phase 1)', () {
    test('drops and recreates the table (big-bang rebuild)', () {
      expect(sql, contains('drop table if exists iam.audit_logs cascade'));
      expect(sql, contains('create table iam.audit_logs ('));
    });

    test('carries the V2 Audit Activity columns, not the legacy ones', () {
      // Scope the legacy-absence check to the CREATE TABLE block — the writer
      // below deliberately keeps an old param named p_subject_type.
      final tStart = sql.indexOf('create table iam.audit_logs (');
      final tEnd = sql.indexOf(');', tStart);
      final table = sql.substring(tStart, tEnd < 0 ? sql.length : tEnd);
      const v2Columns = <String>[
        'activity_code',
        'event_code',
        'event_category',
        'title_snapshot',
        'actor_type',
        'actor_membership_id',
        'actor_display_name_snapshot',
        'actor_context_label',
        'actor_snapshot',
        'target_type',
        'target_id',
        'target_display_name_snapshot',
        'target_secondary_identifier',
        'target_snapshot',
        'correlation_id',
        'source_event_refs',
        'detail_items',
        'redaction_flags',
      ];
      for (final col in v2Columns) {
        expect(table, contains(col), reason: 'missing V2 column: $col');
      }
      // Legacy columns are gone from the table (rebuilt from scratch).
      expect(table, isNot(contains('subject_type')));
      expect(table, isNot(contains('subject_id')));
      expect(table, isNot(contains('before_state')));
      expect(table, isNot(contains('after_state')));
    });

    test('enforces the V2 check constraints', () {
      expect(sql, contains("check (scope in ('tenant', 'platform'))"));
      expect(sql, contains('check (scope <> \'tenant\' or tenant_id is not null)'));
      expect(sql, contains("check (result in ('success', 'blocked', 'error'))"));
      expect(
        sql,
        contains(
          "check (actor_type in ('platform_user', 'tenant_member', 'platform_operator', 'system'))",
        ),
      );
    });

    test('creates the six V2 indexes', () {
      const indexes = <String>[
        'audit_logs_tenant_occurred_idx',
        'audit_logs_platform_occurred_idx',
        'audit_logs_correlation_idx',
        'audit_logs_activity_idx',
        'audit_logs_actor_user_idx',
        'audit_logs_target_idx',
      ];
      for (final idx in indexes) {
        expect(sql, contains('create index $idx'), reason: 'missing index: $idx');
      }
    });
  });

  group('append_audit_log V2 (Phase 2)', () {
    String appendBody() {
      final start = sql.indexOf('create or replace function iam.append_audit_log(');
      expect(start, isNonNegative);
      final end = sql.indexOf(r'$$;', start);
      return sql.substring(start, end < 0 ? sql.length : end);
    }

    test('drops the old overload so 12-arg calls are unambiguous', () {
      // Without this drop, two append_audit_log overloads coexist and a 12-arg
      // call fails with "function is not unique" (42725).
      expect(sql, contains('drop function if exists iam.append_audit_log('));
      expect(
        sql,
        contains('text, uuid, uuid, text, text, text, text, text, text, jsonb, jsonb, text[]'),
      );
    });

    test('keeps the old 12-param signature so callers need no change', () {
      final fn = appendBody();
      expect(fn, contains('p_subject_type text'));
      expect(fn, contains('p_subject_id text'));
      expect(fn, contains('p_before jsonb'));
      expect(fn, contains('p_after jsonb'));
      // Optional rich V2 params added with defaults.
      expect(fn, contains('p_activity_code text default null'));
      expect(fn, contains('p_detail_items jsonb default null'));
      expect(fn, contains('p_correlation_id text default null'));
    });

    test('inserts the V2 column set, mapping subject → target', () {
      final fn = appendBody();
      expect(fn, contains('insert into iam.audit_logs ('));
      expect(fn, contains('activity_code'));
      expect(fn, contains('target_type, target_id, target_display_name_snapshot'));
      expect(fn, contains('detail_items'));
      expect(fn, contains('correlation_id'));
      // Legacy audit columns are not written.
      expect(fn, isNot(contains('before_state')));
      expect(fn, isNot(contains('after_state')));
    });

    test('does not persist the target id as its display name', () {
      final fn = appendBody();
      expect(
        fn,
        contains("coalesce(nullif(trim(coalesce(p_target_display_name, '')), ''), '')"),
      );
      expect(
        fn,
        isNot(
          contains(
            "coalesce(nullif(trim(coalesce(p_target_display_name, '')), ''), p_subject_id)",
          ),
        ),
      );
    });

    test('redacts recursively and derives event category for legacy callers', () {
      expect(sql, contains('create or replace function iam._audit_redact('));
      expect(sql, contains('iam._audit_redact(v_val)'));
      expect(sql, contains('create or replace function iam._audit_event_category('));
      expect(
        appendBody(),
        contains('coalesce(p_event_category, iam._audit_event_category(p_event_code))'),
      );
    });

    test('registers every literal active append event code', () {
      final categoryStart = sql.indexOf(
        'create or replace function iam._audit_event_category(',
      );
      final categoryEnd = sql.indexOf(
        'revoke all on function iam._audit_event_category',
        categoryStart,
      );
      final categoryBody = sql.substring(categoryStart, categoryEnd);
      final literalEvent = RegExp(r"p_event_code\s*=>\s*'([^']+)'");
      final eventCodes = <String>{};

      for (final file in migrations.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.sql') || file.path.contains('/_archive/')) {
          continue;
        }
        for (final match in literalEvent.allMatches(file.readAsStringSync())) {
          eventCodes.add(match.group(1)!);
        }
      }

      expect(eventCodes, isNotEmpty);
      for (final code in eventCodes) {
        expect(categoryBody, contains("'$code'"), reason: code);
      }
    });

    test('sensible defaults keep the mapping mechanical', () {
      final fn = appendBody();
      // actor_type defaults from scope.
      expect(fn, contains("when p_scope = 'platform' then 'platform_operator'"));
      // correlation_id defaults from tracking / generated.
      expect(fn, contains('gen_random_uuid()::text'));
      // old before/after preserved into source_event_refs.
      expect(fn, contains('source_event_refs'));
    });

    test('records the allowlisted caller app and preserves backend fallback', () {
      final fn = appendBody();
      expect(fn, contains("current_setting('request.headers', true)"));
      expect(fn, contains("'x-vet45-app'"));
      expect(fn, contains("v_request_source in ('tenant_app', 'platform_admin_app')"));
      expect(fn, contains('else p_source'));
      expect(fn, contains('v_source, v_correlation, p_tracking_id'));
    });
  });

  group('read RPCs read V2 columns, keep output shape (Phase 4)', () {
    test('all four read RPCs are present', () {
      expect(sql, contains('create or replace function iam.get_platform_audit_log('));
      expect(sql, contains('create or replace function iam.search_platform_audit_logs('));
      expect(sql, contains('create or replace function iam.search_tenant_audit_logs_v2('));
      expect(sql, contains('create or replace function iam.get_tenant_audit_log('));
    });

    test('reads source from V2 columns, not the dropped legacy ones', () {
      // Filters/selects now use the V2 columns.
      expect(sql, contains('a.target_type = p_target_type'));
      expect(sql, contains('a.target_id = p_target_id'));
      expect(sql, contains('a.correlation_id = p_correlation_id'));
      expect(sql, contains("source_event_refs->0->'before'"));
      // No read references the removed legacy columns.
      expect(sql, isNot(contains('a.subject_type')));
      expect(sql, isNot(contains('a.before_state')));
      expect(sql, isNot(contains('a.after_state')));
      expect(sql, isNot(contains('v_row.subject_type')));
    });

    test('output keys stay stable so the Dart audit layer is unchanged', () {
      // The wire keys the DTOs read remain identical.
      expect(sql, contains("'subject'"));
      expect(sql, contains("'before_state'"));
      expect(sql, contains("'after_state'"));
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
