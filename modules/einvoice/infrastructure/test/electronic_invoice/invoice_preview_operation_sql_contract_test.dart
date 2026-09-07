import 'dart:io';

import 'package:test/test.dart';

Directory _repoRoot() {
  var dir = Directory.current;
  while (!Directory('${dir.path}/supabase/migrations/_drafts').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      break;
    }
    dir = parent;
  }
  return dir;
}

String _extractFunction(String sql, String signaturePrefix) {
  final start = sql.indexOf(signaturePrefix);
  expect(start, greaterThanOrEqualTo(0), reason: 'missing $signaturePrefix');
  final nextCreate = sql.indexOf(
    '\ncreate or replace function',
    start + signaturePrefix.length,
  );
  return sql.substring(start, nextCreate > start ? nextCreate : sql.length);
}

void main() {
  late String schemaSql;
  late String rpcSql;

  setUpAll(() {
    final root = _repoRoot().path;
    schemaSql = File(
      '$root/supabase/migrations/_drafts/005_einvoice_buyer_completion_and_preview_schema.sql',
    ).readAsStringSync();
    rpcSql = File(
      '$root/supabase/migrations/_drafts/006_einvoice_buyer_completion_and_preview_rpcs.sql',
    ).readAsStringSync();
  });

  test('draft 005 defines invoice_preview_operations', () {
    expect(
      schemaSql,
      contains(
        'create table if not exists einvoice.invoice_preview_operations',
      ),
    );
    expect(schemaSql, contains('preview_payload jsonb null'));
    expect(schemaSql, contains('provider_connection_id uuid not null'));
    expect(
      schemaSql,
      isNot(contains('alter table einvoice.provider_interaction_records')),
    );
    expect(schemaSql, contains('einvoice.invoice_preview_operations'));
    expect(
      schemaSql,
      contains(
        'Touches: einvoice.buyer_invoice_completions, einvoice.invoice_preview_operations',
      ),
    );
  });

  test('preview RPC names unchanged and use invoice_preview_operations', () {
    expect(rpcSql, contains('einvoice.request_invoice_preview'));
    expect(rpcSql, contains('einvoice.get_invoice_preview'));
    expect(rpcSql, contains('einvoice.store_preview_result'));

    final requestFn = _extractFunction(
      rpcSql,
      'create or replace function einvoice.request_invoice_preview(',
    );
    final getFn = _extractFunction(
      rpcSql,
      'create or replace function einvoice.get_invoice_preview(',
    );
    final storeFn = _extractFunction(
      rpcSql,
      'create or replace function einvoice.store_preview_result(',
    );

    expect(requestFn, contains('invoice_preview_operations'));
    expect(requestFn, isNot(contains('provider_interaction_records')));
    expect(getFn, contains('invoice_preview_operations'));
    expect(getFn, isNot(contains('provider_interaction_records')));
    expect(storeFn, contains('invoice_preview_operations'));
    expect(storeFn, isNot(contains('provider_interaction_records')));
  });

  test('rejects daily observation identity in RPC drafts', () {
    expect(rpcSql, isNot(contains('seed_due_provider_observation')));
    expect(rpcSql, isNot(contains('UTC-day')));
    expect(
      rpcSql,
      isNot(matches(RegExp(r'YYYY-MM-DD.*observation', caseSensitive: false))),
    );
  });
}
