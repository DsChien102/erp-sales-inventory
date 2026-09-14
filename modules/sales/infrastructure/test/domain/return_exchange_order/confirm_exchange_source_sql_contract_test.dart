import 'dart:io';
import 'package:test/test.dart';

void main() {
  late final String confirmSql;
  setUpAll(() {
    final sql = _readSql(
      draftRelative:
          'supabase/migrations/_drafts/014_sales_return_exchange_confirmation_rpcs.sql',
      promotedRelative:
          'supabase/migrations/20260904001_sales_normalize_outbox_and_commands.sql',
    );
    final s = sql.indexOf('create or replace function sales.confirm_return_exchange(');
    final e = sql.indexOf('\n\$\$;', s);
    confirmSql = sql.substring(s, e);
  });

  test('confirm accepts a returned line sourced from an exchange line', () {
    expect(confirmSql, contains('source_exchange_line_id'));
    // The blanket "returned requires original" rejection is relaxed.
    expect(
      confirmSql,
      isNot(contains("rl.line_role = 'returned'\n          and (\n            rl.original_sales_order_line_id is null")),
    );
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
