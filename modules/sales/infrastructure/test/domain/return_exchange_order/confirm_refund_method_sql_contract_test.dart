import 'dart:io';

import 'package:test/test.dart';

/// SQL contract — khoản hoàn khi xác nhận đổi/trả ghi đúng phương thức người
/// dùng chọn (trước đây ghi cứng 'cash').
void main() {
  final sql = _readMigration('20260904001_sales_normalize_outbox_and_commands.sql');

  String settleCall(String fn, String suffix) {
    final start = fn.indexOf("|| '$suffix')");
    expect(start, greaterThan(-1), reason: suffix);
    return fn.substring(start, fn.indexOf('expected_source_version', start));
  }

  test('confirm refund uses the chosen payment method like the collect', () {
    final confirm = _lastFunctionBlock(sql, 'sales.confirm_return_exchange');
    const chosen = "method => coalesce(nullif(btrim(payment_method), ''), 'cash')::text,";
    expect(settleCall(confirm, ':refund'), contains(chosen));
    expect(settleCall(confirm, ':collect'), contains(chosen));
    expect(confirm, isNot(contains("method => 'cash'::text")));
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
