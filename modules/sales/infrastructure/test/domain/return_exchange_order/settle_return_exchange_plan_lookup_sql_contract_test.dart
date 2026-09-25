import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — settle tìm bản định giá theo đúng phiên đổi/trả khi có
/// `return_exchange_id`, để nhiều phiên cùng `correlation_id` (một lần mở app)
/// không làm thu thêm bị «missing or ambiguous».
void main() {
  final settlementSql = _readMigration('20260830013_sales_return_exchange_settlement_rpcs.sql');
  final confirmSql = _readMigration('20260904001_sales_normalize_outbox_and_commands.sql');

  test('settle resolves the plan by return_exchange_id before any correlation lookup', () {
    final settle = _lastFunctionBlock(settlementSql, 'sales.settle_return_exchange_difference');
    const byId = 'if settle_return_exchange_difference.return_exchange_id is not null then';
    expect(settle, contains(byId));
    final byIdAt = settle.indexOf(byId);
    final correlationAt = settle.indexOf("coalesce(rx.correlation_id, '')");
    expect(correlationAt, greaterThan(byIdAt));
    final byIdBlock = settle.substring(byIdAt, correlationAt);
    expect(
      byIdBlock,
      contains(
        'and return_exchange_valuations.return_exchange_order_id\n'
        '        = settle_return_exchange_difference.return_exchange_id',
      ),
    );
    expect(byIdBlock, contains("'Stored settlement plan is missing.'"));
    expect(byIdBlock, isNot(contains('correlation_id')));
  });

  test('refund without id still fails and correlation lookup stays as fallback', () {
    final settle = _lastFunctionBlock(settlementSql, 'sales.settle_return_exchange_difference');
    expect(settle, contains("elsif operation = 'refund' then"));
    expect(settle, contains("'Refund settlement requires return_exchange_id.'"));
    expect(settle, contains("'Settlement plan association is missing or ambiguous.'"));
    expect(settle, isNot(contains("if operation = 'refund' then\n    if return_exchange_id is null then")));
  });

  test('confirm passes the session id to the collect settle', () {
    final confirm = _lastFunctionBlock(confirmSql, 'sales.confirm_return_exchange');
    final start = confirm.indexOf("|| ':collect')");
    final end = confirm.indexOf("':confirm-collect'", start);
    expect(start, greaterThan(-1));
    expect(confirm.substring(start, end), contains('return_exchange_id => v_session.id,'));
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
