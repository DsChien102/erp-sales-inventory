import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — IAM refactor bảng 13 `iam.audit_logs`
/// (docs/superpowers/specs/iam-schema-refactor/13-audit-logs.md).
void main() {
  final sql = _readMigration('20260826004_iam_audit_logs_v2_rebuild.sql');

  test('audit_logs table has occurred_at and no created_at', () {
    final start = sql.indexOf('create table iam.audit_logs (');
    final table = sql.substring(start, sql.indexOf('\n);', start));
    expect(table, contains('occurred_at timestamptz not null default now(),'));
    expect(table, isNot(contains('created_at')));
  });

  test('append_audit_log no longer writes created_at', () {
    final body = _lastFunctionBlock(sql, 'iam.append_audit_log');
    expect(body, contains('redaction_flags, occurred_at\n'));
    expect(body, isNot(contains('occurred_at, created_at')));
    expect(body, isNot(contains('coalesce(p_occurred_at, v_now), v_now')));
  });
}

String _readMigration(String fileName) {
  final root = _findRepoRoot();
  return File('${root.path}/supabase/migrations/$fileName').readAsStringSync();
}

/// Last `create or replace function <qualifiedName>(` … `$$;` in [sql].
String _lastFunctionBlock(String sql, String qualifiedName) {
  final start = sql.lastIndexOf('create or replace function $qualifiedName(');
  if (start < 0) {
    throw StateError('$qualifiedName not found');
  }
  final end = sql.indexOf(r'$$;', start);
  return sql.substring(start, end + 3);
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
