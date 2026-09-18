import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — IAM refactor bảng 14 password reset
/// (docs/superpowers/specs/iam-schema-refactor/14-password-reset.md).
void main() {
  final sql = File(
    '${_findRepoRoot().path}/supabase/migrations/20260811021_iam_password_reset_operations.sql',
  ).readAsStringSync();

  test('no legacy-shape upgrade guards remain', () {
    expect(sql, isNot(contains('drop table iam.password_reset_operations cascade')));
    expect(sql, isNot(contains('delivery_code')));
    expect(sql, isNot(contains('add column if not exists code_hash')));
  });

  test('table still stores only the code hash', () {
    final start = sql.indexOf('create table if not exists iam.password_reset_operations (');
    final table = sql.substring(start, sql.indexOf('\n);', start));
    expect(table, contains('code_hash text,'));
    expect(table, contains('attempt_count int not null default 0,'));
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
