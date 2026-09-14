import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String promotedSql;
  late String draftSql;

  setUpAll(() {
    final root = _findRepoRoot();
    promotedSql = File(
      '${root.path}/supabase/migrations/'
      '20260830001_iam_active_store_context_group_a.sql',
    ).readAsStringSync();
    draftSql = File(
      '${root.path}/supabase/migrations/_drafts/'
      '019_iam_get_session_context_multi_tenant.sql',
    ).readAsStringSync();
  });

  group('IAM active-store promoted DDL contract', () {
    test('defines stores and membership_store_scopes', () {
      expect(promotedSql, contains('create table if not exists iam.stores'));
      expect(
        promotedSql,
        contains('create table if not exists iam.membership_store_scopes'),
      );
      expect(
        promotedSql,
        contains("set display_name = excluded.display_name, status = 'active'"),
      );
    });
  });

  group('IAM get_session_context multi-tenant draft contract', () {
    test('declares Touches for patched RPCs', () {
      final touches = draftSql
          .split('\n')
          .firstWhere((line) => line.startsWith('-- Touches:'));
      expect(touches, contains('iam.get_session_context'));
      expect(touches, contains('iam.bootstrap_owner'));
    });

    test('filters active memberships and returns null when ambiguous', () {
      final body = _functionBody(
        draftSql,
        'create or replace function iam.get_session_context(',
      );
      expect(body, contains("m.status = 'active'"));
      expect(body, contains('v_active_count > 1'));
      expect(body, contains('return null;'));
      expect(
        body,
        isNot(contains('Exactly one tenant context is required.')),
      );
    });

    test('bootstrap_owner is tenant-scoped', () {
      expect(
        draftSql,
        contains('create or replace function iam.bootstrap_owner('),
      );
      expect(draftSql, contains('p_tenant_id uuid'));
      expect(draftSql, contains("drop function if exists iam.bootstrap_owner(text)"));

      final getSessionBody = _functionBody(
        draftSql,
        'create or replace function iam.get_session_context(',
      );
      expect(
        getSessionBody,
        contains('perform iam.bootstrap_owner(v_tenant_id, \'My Store\')'),
      );

      final bootstrapBody = _functionBody(
        draftSql,
        'create or replace function iam.bootstrap_owner(',
      );
      expect(bootstrapBody, contains('p_tenant_id'));
      expect(
        bootstrapBody,
        isNot(contains('Exactly one tenant context is required.')),
      );
      expect(bootstrapBody, contains("if v_role not in ('owner', 'store_owner') then"));
      expect(bootstrapBody, contains('"code":"PERMISSION_DENIED"'));
      expect(bootstrapBody, contains('insert into iam.stores'));
    });

    test('session payload includes is_owner and active store fields', () {
      final body = _functionBody(
        draftSql,
        'create or replace function iam.get_session_context(',
      );
      expect(body, contains("'is_owner', coalesce(v_is_owner, false)"));
      expect(body, contains("'active_store_id', v_active_store_id"));
      expect(body, contains("'active_store_code', v_active_store_code"));
      expect(
        body,
        contains("'active_store_display_name', v_active_store_display_name"),
      );
    });
  });
}

String _functionBody(String sql, String marker) {
  final start = sql.indexOf(marker);
  expect(start, greaterThanOrEqualTo(0), reason: 'missing $marker');
  final begin = sql.indexOf('as \$\$', start);
  expect(begin, greaterThan(start));
  final end = sql.indexOf('\$\$;', begin);
  expect(end, greaterThan(begin));
  return sql.substring(begin, end);
}

Directory _findRepoRoot() {
  var dir = Directory.current;
  while (true) {
    final candidate = Directory('${dir.path}/supabase/migrations');
    if (candidate.existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not locate repo root from ${Directory.current.path}');
    }
    dir = parent;
  }
}
