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

void main() {
  late String sql;

  setUpAll(() {
    final draft = File(
      '${_repoRoot().path}/supabase/migrations/_drafts/'
      '001_einvoice_configuration_schema.sql',
    );
    expect(draft.existsSync(), isTrue);
    sql = draft.readAsStringSync();
  });

  test('provider interaction contract is typed and payload-free', () {
    expect(sql, contains('correlation_id uuid not null'));
    expect(sql, contains("direction in ('OUTBOUND','INBOUND_CALLBACK')"));
    expect(sql, contains('request_reference varchar(255) not null'));
    expect(sql, isNot(contains('request_summary')));
    expect(sql, isNot(contains('response_summary')));
  });

  test('rejects preview state columns on provider_interaction_records', () {
    final tableStart = sql.indexOf(
      'create table if not exists einvoice.provider_interaction_records',
    );
    expect(tableStart, greaterThanOrEqualTo(0));
    final nextCreate = sql.indexOf(
      '\ncreate table if not exists',
      tableStart + 1,
    );
    final tableBody = sql.substring(
      tableStart,
      nextCreate > tableStart ? nextCreate : sql.length,
    );
    expect(tableBody, isNot(contains('sales_order_id')));
    expect(tableBody, isNot(contains('viewer_ref')));
    expect(tableBody, isNot(contains('preview_payload')));
    expect(tableBody, isNot(contains('interaction_type')));
    expect(
      tableBody,
      isNot(matches(RegExp(r'(?<!provider_)connection_id uuid'))),
    );
  });

  test('requires canonical interaction fields and checks', () {
    expect(sql, contains('provider_connection_id uuid not null'));
    expect(sql, contains('operation_type text not null'));
    expect(sql, contains('target_type text not null'));
    expect(sql, contains('target_id uuid not null'));
    expect(sql, contains('response_reference varchar(255) null'));
    expect(sql, contains('provider_reference varchar(255) null'));
    expect(sql, contains("status in ('STARTED','COMPLETED')"));
    expect(
      sql,
      contains("'SUCCEEDED','DEFINITE_FAILURE','TIMEOUT','UNAVAILABLE'"),
    );
    expect(sql, contains("'NOT_FOUND','MISMATCH','CHECK_REQUIRED'"));
    expect(sql, contains('safe_error_code varchar(100) null'));
    expect(sql, contains('unique (tenant_id, correlation_id, operation_type)'));
    expect(
      sql,
      contains(
        'alter table einvoice.provider_interaction_records enable row level security',
      ),
    );
    expect(
      sql,
      contains('revoke all on einvoice.provider_interaction_records'),
    );
  });

  test('rejects varchar correlation_id on provider_interaction_records', () {
    expect(sql, isNot(contains('correlation_id varchar')));
    expect(sql, isNot(contains('correlation_id text')));
  });
}
