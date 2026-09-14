import 'dart:io';

import 'package:test/test.dart';

/// Contract for the DT return/exchange code derived from the source DH order
/// code, with a per-order occurrence suffix (design 2026-08-19).
void main() {
  late final String sessionSql;
  late final String startSql;
  late final String schemaSql;

  setUpAll(() {
    sessionSql = _readSql(
      draftRelative:
          'supabase/migrations/_drafts/012_sales_return_exchange_session_rpcs.sql',
      promotedRelative:
          'supabase/migrations/20260830012_sales_return_exchange_session_rpcs.sql',
    );
    startSql = _functionSql(sessionSql, 'sales.start_return_exchange');
    schemaSql = _readSql(
      draftRelative: 'supabase/migrations/_drafts/005_sales_rebuild_schema.sql',
      promotedRelative:
          'supabase/migrations/20260830005_sales_rebuild_schema.sql',
    );
  });

  test('builds DT reference from the source order code, not the order UUID', () {
    // Prefix swap DH -> DT on the source order_code.
    expect(startSql, contains("'DT'"));
    expect(startSql, contains("regexp_replace(v_order.order_code, '^DH', '')"));
    // Old UUID-slice construction is gone.
    expect(startSql, isNot(contains("substr(replace(v_order.id::text")));
  });

  test('suffix is a 2-digit per-order occurrence starting at 01', () {
    // Sequence = number of existing return/exchange orders for this order + 1.
    expect(
      startSql,
      contains('from sales.return_exchange_orders'),
    );
    expect(startSql, contains('lpad(v_seq::text, 2, '));
    // Not the wrap-around modulo of the old daily counter.
    expect(startSql, isNot(contains('v_seq % 100')));
  });

  test('serialises concurrent starts on the same source order', () {
    expect(startSql, contains('pg_advisory_xact_lock'));
    expect(startSql, contains('start_return_exchange:order:'));
  });

  test('drops the unused daily reference-number counter', () {
    expect(sessionSql, isNot(contains('return_exchange_number_counters')));
    expect(schemaSql, isNot(contains('return_exchange_number_counters')));
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

String _functionSql(String sql, String function) {
  final start = sql.indexOf('create or replace function $function(');
  if (start < 0) throw StateError('Missing function $function.');
  final end = sql.indexOf('\n\$\$;', start);
  if (end < 0) throw StateError('Missing terminator for $function.');
  return sql.substring(start, end + '\n\$\$;'.length);
}
