import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = findRepoRoot();
    sql = File(
      '${root.path}/supabase/migrations/20260811016_iam_tenant_readiness_activate.sql',
    ).readAsStringSync();
  });

  test('provisioning without owner distinguishes pending vs expired invitation', () {
    final body = functionBody(sql, 'iam.get_tenant_readiness');
    expect(body, contains("'OWNER_ACCEPTANCE_PENDING'"));
    expect(body, contains("'OWNER_INVITATION_EXPIRED'"));
    expect(body, contains('i.expires_at > now()'));
    expect(body, contains("v_tenant.status = 'provisioning'"));
    expect(body, contains("'OWNER_MEMBERSHIP_INVALID'"));
    expect(body, contains('jsonb_array_length(v_blockers) = 0'));
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
