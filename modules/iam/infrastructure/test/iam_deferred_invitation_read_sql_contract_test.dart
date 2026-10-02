import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = findRepoRoot();
    const files = [
      '20260811010_iam_platform_tenants_read.sql',
      '20260911003_iam_get_platform_tenant_owner_from_invitation.sql',
    ];
    sql = files
        .map((f) => File('${root.path}/supabase/migrations/$f').readAsStringSync())
        .join('\n');
  });

  test('detail prefers accepted owner and falls back to pending invitation', () {
    final body = functionBody(sql, 'iam.get_platform_tenant');
    expect(body, contains('from iam.memberships m'));
    expect(body, contains('from iam.tenant_invitations i'));
    expect(body, contains("i.is_owner is true"));
    expect(body, contains("i.status = 'pending'"));
    expect(body, contains('i.expires_at > now()'));
    expect(body, contains('owner_priority'));
    expect(body, contains('order by owner_priority, owner_created_at desc'));
    expect(body, contains("'owner_user_id', v_owner.user_id"));
    expect(body, contains("'members', coalesce(v_members, '[]'::jsonb)"));
    expect(body, contains("'owner_invitation_email', v_owner_inv.invitee_email"));
    expect(body, contains("'owner_invitation_state',"));
    expect(body, contains("'owner_invitation_expires_at', v_owner_inv.expires_at"));
  });

  test('search uses the same pending-owner fallback without inflating member count', () {
    final body = functionBody(sql, 'iam.search_platform_tenants');
    expect(body, contains('left join lateral'));
    expect(body, contains('iam.tenant_invitations'));
    expect(body, contains("status = 'pending'"));
    expect(body, contains('count(distinct m.user_id)'));
    expect(body, isNot(contains('count(distinct i.invitee_email)')));
  });
}

String functionBody(String sql, String qualifiedName) {
  final start = sql.lastIndexOf(
    'create or replace function $qualifiedName(',
  );
  if (start < 0) throw StateError('$qualifiedName not found');
  final end = sql.indexOf(r'$$;', start);
  if (end < 0) throw StateError('$qualifiedName terminator not found');
  return sql.substring(start, end + 3);
}

Directory findRepoRoot() {
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
