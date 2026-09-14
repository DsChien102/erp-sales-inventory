import 'dart:io';
import 'package:test/test.dart';

void main() {
  late final String schemaSql;
  setUpAll(() {
    schemaSql = _readSql(
      draftRelative: 'supabase/migrations/_drafts/005_sales_rebuild_schema.sql',
      promotedRelative:
          'supabase/migrations/20260830005_sales_rebuild_schema.sql',
    );
  });

  test('return_exchange_lines carries an exchange-source column', () {
    expect(schemaSql, contains('source_exchange_line_id uuid'));
  });

  test('exchange-source is a self FK target and reference', () {
    expect(schemaSql, contains('return_exchange_lines_tenant_id_unique'));
    expect(schemaSql, contains('return_exchange_lines_source_exchange_fk'));
  });

  test('returned line references exactly one source (original XOR exchange)', () {
    expect(schemaSql, contains('return_exchange_lines_returned_single_source'));
    // The old original-only check body is gone from the table definition (the
    // name may still appear in an idempotent `drop constraint if exists`).
    expect(
      schemaSql,
      isNot(contains("line_role <> 'returned' or original_sales_order_line_id is not null")),
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
