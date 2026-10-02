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

String _extractTable(String sql, String tablePrefix) {
  final start = sql.indexOf(tablePrefix);
  expect(start, greaterThanOrEqualTo(0), reason: 'missing $tablePrefix');
  final end = sql.indexOf(');', start);
  expect(
    end,
    greaterThanOrEqualTo(0),
    reason: 'missing closing ); for $tablePrefix',
  );
  return sql.substring(start, end + 2);
}

void main() {
  late String sql;
  late String deliveriesTable;

  setUpAll(() {
    final draft = File(
      '${_repoRoot().path}/supabase/migrations/_drafts/'
      '013_einvoice_delivery_schema_and_start_rpcs.sql',
    );
    expect(
      draft.existsSync(),
      isTrue,
      reason: 'S5 draft SQL 013 must exist under supabase/migrations/_drafts/',
    );
    sql = draft.readAsStringSync();
    deliveriesTable = _extractTable(
      sql,
      'create table if not exists einvoice.invoice_deliveries',
    );
  });

  group('S5 draft metadata', () {
    test('declares Kind, Intent, and Touches for start/read RPCs', () {
      expect(sql, contains('-- Kind:'));
      expect(sql, contains('-- Intent: einvoice_s5_delivery_schema_and_start'));
      expect(sql, contains('-- Touches:'));
      for (final touch in [
        'einvoice.start_auto_delivery',
        'einvoice.send_electronic_invoice',
        'einvoice.get_send_invoice_sheet_context',
        'einvoice.get_invoice_delivery_history',
        'einvoice.load_delivery_attempt_context',
      ]) {
        expect(sql, contains(touch));
      }
    });

    test('does not introduce Task-6 result/reconciliation RPCs', () {
      expect(sql, isNot(contains('prepare_delivery_provider_call')));
      expect(sql, isNot(contains('record_delivery_result')));
      expect(sql, isNot(contains('record_delivery_command_dead_letter')));
      expect(sql, isNot(contains('load_delivery_reconciliation_context')));
      expect(sql, isNot(contains('record_delivery_reconciliation_check')));
      expect(sql, isNot(contains('get_order_invoice_projection')));
    });
  });

  group('invoice_deliveries canonical schema', () {
    test('has every frozen column with exact names', () {
      final expected = [
        'id',
        'tenant_id',
        'electronic_invoice_id',
        'delivery_no',
        'delivery_intent',
        'recipient_snapshot_schema_version',
        'recipient_snapshot',
        'idempotency_key',
        'status',
        'retry_count',
        'provider_connection_id',
        'provider_delivery_reference',
        'provider_request_reference',
        'failure_code',
        'failure_message',
        'failure_source',
        'initiated_by_actor_type',
        'initiated_by_actor_id',
        'submitted_at',
        'completed_at',
        'created_at',
        'version',
      ];
      for (final field in expected) {
        expect(
          deliveriesTable,
          contains(field),
          reason: 'invoice_deliveries missing $field',
        );
      }
      expect(deliveriesTable, contains('version bigint not null default 0'));
      expect(deliveriesTable, contains('recipient_snapshot jsonb'));
    });

    test(
      'uses enum/check constraints for status, intent, and actor',
      () {
        expect(
          deliveriesTable,
          contains(
            "status in ('QUEUED', 'SUBMITTED', 'SUCCEEDED', 'FAILED', 'UNKNOWN')",
          ),
        );
        expect(
          deliveriesTable,
          contains("delivery_intent in ('INITIAL_SEND', 'RESEND')"),
        );
        expect(
          deliveriesTable,
          contains('retry_count between 0 and 2'),
        );
        expect(
          deliveriesTable,
          contains("failure_source in ('PROVIDER', 'INTERNAL')"),
        );
        expect(
          deliveriesTable,
          contains("initiated_by_actor_type in ('SYSTEM', 'USER')"),
        );
      },
    );

    test('keeps completion and failure message fields nullable', () {
      expect(deliveriesTable, contains('completed_at timestamptz'));
      expect(deliveriesTable, contains('failure_message text'));
      expect(deliveriesTable, contains('provider_delivery_reference text'));
      expect(deliveriesTable, contains('failure_code text'));
    });

    test('enforces unique delivery_no and idempotency key', () {
      expect(
        deliveriesTable,
        contains('unique (tenant_id, electronic_invoice_id, delivery_no)'),
      );
      expect(deliveriesTable, contains('unique (tenant_id, idempotency_key)'));
    });
  });

  group('indexes, RLS, and immutable recipient semantics', () {
    test(
      'creates partial unique indexes for INITIAL_SEND and active locks',
      () {
        expect(sql, contains("where delivery_intent = 'INITIAL_SEND'"));
        expect(
          sql,
          isNot(contains("where status in ('PROCESSING','UNKNOWN')")),
        );
        expect(sql, contains("where status in ('QUEUED','SUBMITTED')"));
        expect(sql, contains('create unique index'));
        expect(sql, isNot(contains('delivery_attempts')));
      },
    );

    test('enables tenant RLS and revokes client table access', () {
      expect(
        sql,
        contains(
          'alter table einvoice.invoice_deliveries enable row level security',
        ),
      );
      expect(
        sql,
        contains(
          'revoke all on einvoice.invoice_deliveries from anon, authenticated',
        ),
      );
      expect(sql, isNot(contains('delivery_attempts')));
    });

    test('never mutates recipient_snapshot after insert in this draft', () {
      expect(
        RegExp(r'recipient_snapshot\s*=').hasMatch(sql),
        isFalse,
        reason: 'recipient_snapshot must stay immutable after insert',
      );
      expect(sql, contains('recipient_snapshot,'));
    });

    test('does not add is_simulated columns via alter', () {
      expect(sql, isNot(contains('is_simulated')));
      expect(
        sql,
        isNot(
          contains(
            'alter table einvoice.invoice_deliveries add column if not exists is_simulated',
          ),
        ),
      );
      expect(sql, isNot(contains('delivery_attempts')));
    });

    test('does not copy provider/raw/recipient text into message columns', () {
      expect(sql, isNot(contains('provider_result_message =')));
      expect(sql, isNot(contains('failure_message = v_')));
      expect(sql, isNot(contains('exception_message')));
      expect(sql, isNot(contains('http_body')));
    });
  });
}
