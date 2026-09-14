import 'dart:io';
import 'package:test/test.dart';

void main() {
  late final String returnableSql;
  late final String precheckSql;
  setUpAll(() {
    final sql = _readSql(
      draftRelative:
          'supabase/migrations/_drafts/012_sales_return_exchange_session_rpcs.sql',
      promotedRelative:
          'supabase/migrations/20260830012_sales_return_exchange_session_rpcs.sql',
    );
    returnableSql = _fn(sql, 'sales.get_returnable_order_lines');
    precheckSql = _fn(sql, 'sales.precheck_return_exchange');
  });

  test('returnable pool includes confirmed exchange lines as units', () {
    expect(returnableSql, contains("line_role = 'exchange'"));
    expect(returnableSql, contains('sourceExchangeLineId'));
  });

  test('returnable subtracts returns that reference the exchange source', () {
    expect(returnableSql, contains('source_exchange_line_id'));
  });

  test('precheck counts exchange-line units when deciding returnable > 0', () {
    expect(precheckSql, contains("line_role = 'exchange'"));
  });
}

String _readSql({
  required String draftRelative,
  required String promotedRelative,
}) {
  final candidates = <File>[
    File(draftRelative),
    File('../../../$draftRelative'),
    File('../../../../$draftRelative'),
    File(promotedRelative),
    File('../../../$promotedRelative'),
    File('../../../../$promotedRelative'),
  ];
  for (final candidate in candidates) {
    if (candidate.existsSync()) {
      return candidate.readAsStringSync();
    }
  }
  throw StateError('Missing SQL for $draftRelative / $promotedRelative');
}

String _fn(String sql, String fn) {
  final s = sql.indexOf('create or replace function $fn(');
  final e = sql.indexOf('\n\$\$;', s);
  return sql.substring(s, e);
}
