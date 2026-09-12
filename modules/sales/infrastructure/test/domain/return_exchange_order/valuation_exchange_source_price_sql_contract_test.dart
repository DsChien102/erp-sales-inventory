import 'dart:io';
import 'package:test/test.dart';

void main() {
  late final String evalSql;
  setUpAll(() {
    final sql = _readSql(
      draftRelative:
          'supabase/migrations/_drafts/013_sales_return_exchange_settlement_rpcs.sql',
      promotedRelative:
          'supabase/migrations/20260830013_sales_return_exchange_settlement_rpcs.sql',
    );
    final s = sql.indexOf('create or replace function sales.evaluate_return_exchange_valuation(');
    final e = sql.indexOf('\n\$\$;', s);
    evalSql = sql.substring(s, e);
  });

  test('returned-from-exchange prices at the source exchange line value', () {
    expect(evalSql, contains('source_exchange_line_id'));
    // Uses the exchange line unit_value_minor as the returned "original" price.
    expect(evalSql, contains('unit_value_minor'));
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
