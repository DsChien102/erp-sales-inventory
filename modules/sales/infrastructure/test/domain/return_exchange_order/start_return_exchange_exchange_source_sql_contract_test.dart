import 'dart:io';
import 'package:test/test.dart';

void main() {
  late final String startSql;
  setUpAll(() {
    final sql = _readSql(
      draftRelative:
          'supabase/migrations/_drafts/012_sales_return_exchange_session_rpcs.sql',
      promotedRelative:
          'supabase/migrations/20260830012_sales_return_exchange_session_rpcs.sql',
    );
    final start = sql.indexOf('create or replace function sales.start_return_exchange(');
    final end = sql.indexOf('\n\$\$;', start);
    startSql = sql.substring(start, end);
  });

  test('start persists the exchange source on the returned line', () {
    expect(startSql, contains('source_exchange_line_id'));
  });

  test('returned-from-exchange reads snapshot/price from the source exchange line', () {
    // Reads unit_value_minor / snapshots from return_exchange_lines when source is an exchange line.
    expect(startSql, contains('from sales.return_exchange_lines'));
    expect(startSql, contains('unit_value_minor'));
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
