import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = _findRepoRoot();
    sql = File(
      '${root.path}/supabase/migrations/_drafts/019_iam_tenant_invitation_read.sql',
    ).readAsStringSync();
  });

  group('iam tenant invitation read SQL contract', () {
    test('header Kind/Intent/Touches', () {
      expect(sql, contains('-- Kind: patch'));
      expect(sql, contains('-- Intent: iam_tenant_invitation_read'));
      expect(
        sql,
        contains(
          '-- Touches: iam.list_tenant_invitations, iam.get_tenant_invitation',
        ),
      );
    });

    test('list and detail signatures', () {
      expect(
        sql,
        contains(
          'create or replace function iam.list_tenant_invitations(\n'
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
        contains(
          'create or replace function iam.get_tenant_invitation(\n'
          '  p_tenant_id uuid,\n'
          '  p_invitation_id uuid\n'
          ')',
        ),
      );
    });

    test('auth, permission, validation', () {
      expect(sql, contains("raise exception 'AUTHENTICATION_REQUIRED'"));
      expect(sql, contains("raise exception 'PERMISSION_DENIED'"));
      expect(sql, contains("raise exception 'VALIDATION_ERROR'"));
      expect(sql, contains("iam.has_permission(p_tenant_id, 'tenant.member.view')"));
      expect(
        sql,
        contains(
          "v_status not in ('pending', 'accepted', 'declined', 'revoked', 'expired')",
        ),
      );
      expect(sql, contains('v_limit < 1 or v_limit > 100'));
      expect(sql, contains("lower(trim(coalesce(p_search, '')))"));
    });

    test('effective expired status and opaque cursor page', () {
      expect(
        sql,
        contains(
          "when i.status = 'pending' and i.expires_at <= timezone('utc', now())",
        ),
      );
      expect(sql, contains("then 'expired'"));
      expect(
        sql,
        contains("convert_from(decode(p_cursor, 'hex'), 'UTF8')::jsonb"),
      );
      expect(sql, contains("(v_cursor_payload ->> 'created_at')::timestamptz"));
      expect(sql, contains("(v_cursor_payload ->> 'id')::uuid"));
      expect(sql, contains('(select count(*) from filtered) > v_limit'));
      expect(sql, isNot(contains('if v_count = v_limit then')));
      expect(sql, isNot(contains("split_part(p_cursor, '|'")));
      expect(sql, contains('order by b.created_at desc, b.id desc'));
      expect(sql, contains("'items', coalesce(v_items, '[]'::jsonb)"));
      expect(sql, contains("'next_cursor', v_next_cursor"));
    });

    test('full page does not reference a CTE from a later statement', () {
      final start = sql.indexOf(
        'create or replace function iam.list_tenant_invitations(',
      );
      final end = sql.indexOf('\nend;\n\$\$;', start);
      final body = sql.substring(start, end);

      expect(body, contains('with base as ('));
      expect(body, contains('filtered as ('));
      expect(body, contains('page as ('));
      expect(body, contains('into v_items, v_next_cursor'));
      expect(body, isNot(contains('into v_items, v_count')));
    });

    test('DTO keys, delivery projection, no token/hash, authenticated grants', () {
      for (final key in const [
        'invitation_id',
        'invitee_email',
        'initial_role_id',
        'initial_role_label',
        'status',
        'expires_at',
        'delivery_status',
        'delivery_correlation_id',
        'version',
        'created_at',
        'created_by',
        'last_sent_at',
        'revoked_at',
        'declined_at',
      ]) {
        expect(sql, contains("'$key'"), reason: key);
      }
      expect(sql, contains('iam.email_delivery_outcomes'));
      expect(sql, contains('invited_by_membership_id'));
      expect(sql, isNot(contains("'token'")));
      expect(sql, isNot(contains("'token_hash'")));
      expect(
        sql,
        contains(
          'grant execute on function iam.list_tenant_invitations(uuid, text, text, text, integer)\n'
          '  to authenticated;',
        ),
      );
      expect(
        sql,
        contains(
          'grant execute on function iam.get_tenant_invitation(uuid, uuid)\n'
          '  to authenticated;',
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
