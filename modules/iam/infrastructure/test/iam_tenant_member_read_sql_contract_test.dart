import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = _findRepoRoot();
    sql = File(
      '${root.path}/supabase/migrations/20260811014_iam_tenant_membership_lifecycle.sql',
    ).readAsStringSync();
  });

  group('iam.list_tenant_members S6 contract', () {
    test('Touches header still owns list_tenant_members', () {
      expect(sql, contains('iam.list_tenant_members'));
      expect(
        sql,
        contains('-- Touches:'),
      );
      final touches = sql.split('\n').firstWhere((line) => line.startsWith('-- Touches:'));
      expect(touches, contains('iam.list_tenant_members'));
    });

    test('five-parameter signature and drops legacy one-arg overload', () {
      expect(
        sql,
        contains(
          'create or replace function iam.list_tenant_members(\n'
          '  p_tenant_id uuid,\n'
          '  p_search text,\n'
          '  p_status text,\n'
          '  p_cursor text,\n'
          '  p_limit integer\n'
          ')',
        ),
      );
      expect(
        sql,
        contains('drop function if exists iam.list_tenant_members(uuid);'),
      );
      expect(
        sql,
        isNot(
          contains(
            'create or replace function iam.list_tenant_members(p_tenant_id uuid)\n'
            'returns table (',
          ),
        ),
      );
    });

    test('auth, permission, validation guards', () {
      expect(sql, contains("raise exception 'AUTHENTICATION_REQUIRED'"));
      expect(sql, contains("raise exception 'PERMISSION_DENIED'"));
      expect(sql, contains("raise exception 'VALIDATION_ERROR'"));
      expect(sql, contains("iam.has_permission(p_tenant_id, 'tenant.member.view')"));
      expect(sql, contains("v_status not in ('active', 'inactive', 'removed')"));
      expect(sql, contains('v_limit < 1 or v_limit > 100'));
    });

    test('canonical search, opaque cursor, page shape, DTO keys', () {
      expect(sql, contains("lower(trim(coalesce(p_search, '')))"));
      expect(
        sql,
        contains("convert_from(decode(p_cursor, 'hex'), 'UTF8')::jsonb"),
      );
      expect(sql, contains("(v_cursor_payload ->> 'created_at')::timestamptz"));
      expect(sql, contains("(v_cursor_payload ->> 'id')::uuid"));
      expect(sql, contains('encode('));
      expect(sql, contains('convert_to('));
      expect(sql, contains("'UTF8'"));
      expect(sql, contains("'hex'"));
      expect(sql, contains('(select count(*) from filtered) > v_limit'));
      expect(sql, isNot(contains('if v_count = v_limit then')));
      expect(sql, isNot(contains("split_part(p_cursor, '|'")));
      expect(sql, contains('order by m.created_at desc, m.id desc'));
      expect(sql, contains('limit v_limit + 1'));
      expect(sql, contains("return jsonb_build_object("));
      expect(sql, contains("'items', coalesce(v_items, '[]'::jsonb)"));
      expect(sql, contains("'next_cursor', v_next_cursor"));
      for (final key in const [
        'membership_id',
        'user_id',
        'display_name',
        'email',
        'role_id',
        'role_label',
        'is_owner',
        'status',
        'joined_at',
        'version',
      ]) {
        expect(sql, contains("'$key'"), reason: 'missing DTO key $key');
      }
    });

    test('items and next cursor are derived inside one filtered CTE statement', () {
      final functionStart = sql.indexOf(
        'create or replace function iam.list_tenant_members(',
      );
      final functionEnd = sql.indexOf('\nend;\n\$\$;', functionStart);
      final body = sql.substring(functionStart, functionEnd);

      expect(body, contains('with filtered as ('));
      expect(body, contains('page as ('));
      expect(body, contains('into v_items, v_next_cursor'));
      expect(body, isNot(contains('into v_items, v_count')));
      expect(body, isNot(contains('if v_count = v_limit then')));
    });

    test('joins profiles/auth/roles and grants authenticated only', () {
      expect(sql, contains('auth.users'));
      expect(sql, contains('iam.platform_user_profiles'));
      expect(sql, contains('iam.role_definitions'));
      expect(
        sql,
        contains(
          'revoke all on function iam.list_tenant_members(uuid, text, text, text, integer) from public, anon;',
        ),
      );
      expect(
        sql,
        contains(
          'grant execute on function iam.list_tenant_members(uuid, text, text, text, integer) to authenticated;',
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
