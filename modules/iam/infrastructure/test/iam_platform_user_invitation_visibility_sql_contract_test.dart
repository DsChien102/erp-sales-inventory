import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = findRepoRoot();
    sql = File(
      '${root.path}/supabase/migrations/20260911002_iam_patch_search_phone_status_casts.sql',
    ).readAsStringSync();
  });

  test('platform user list and detail start from real auth users', () {
    for (final name in const ['iam.search_platform_users', 'iam.get_platform_user']) {
      final body = functionBody(sql, name);
      expect(body, contains('from auth.users u'));
      expect(
        body,
        contains('left join iam.platform_user_profiles p on p.user_id = u.id'),
      );
    }
    expect(sql, isNot(contains('full outer join auth.users')));
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
