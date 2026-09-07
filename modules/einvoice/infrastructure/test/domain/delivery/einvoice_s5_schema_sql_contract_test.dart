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
  late String attemptsTable;

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
    attemptsTable = _extractTable(
      sql,
      'create table if not exists einvoice.delivery_attempts',
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
        'trigger_type',
        'channel',
        'recipient_snapshot_schema_version',
        'recipient_snapshot',
        'idempotency_key',
        'intent_hash',
        'status',
        'provider_delivery_reference',
        'provider_result_code',
        'provider_result_message',
        'failure_code',
        'failure_message',
        'initiated_by_actor_type',
        'initiated_by_actor_id',
        'started_at',
        'completed_at',
        'created_at',
        'updated_at',
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
      'uses enum/check constraints for status, intent, trigger, channel',
      () {
        expect(
          deliveriesTable,
          contains("status in ('PROCESSING','SUCCEEDED','FAILED','UNKNOWN')"),
        );
        expect(
          deliveriesTable,
          contains("delivery_intent in ('INITIAL_SEND','RESEND')"),
        );
        expect(
          deliveriesTable,
          contains("trigger_type in ('AUTOMATIC','MANUAL')"),
        );
        expect(deliveriesTable, contains("channel in ('EMAIL')"));
        expect(
          deliveriesTable,
          contains("initiated_by_actor_type in ('SYSTEM','USER')"),
        );
      },
    );

    test('keeps completion and result message fields nullable', () {
      expect(deliveriesTable, contains('completed_at timestamptz null'));
      expect(deliveriesTable, contains('provider_result_message text null'));
      expect(deliveriesTable, contains('failure_message text null'));
      expect(deliveriesTable, contains('provider_delivery_reference'));
      expect(deliveriesTable, contains('provider_result_code'));
      expect(deliveriesTable, contains('failure_code'));
    });

    test('enforces unique delivery_no and idempotency key', () {
      expect(
        deliveriesTable,
        contains('unique (tenant_id, electronic_invoice_id, delivery_no)'),
      );
      expect(deliveriesTable, contains('unique (tenant_id, idempotency_key)'));
    });
  });

  group('delivery_attempts canonical schema', () {
    test('has every frozen column with exact names', () {
      final expected = [
        'id',
        'tenant_id',
        'invoice_delivery_id',
        'attempt_no',
        'status',
        'provider_connection_id',
        'provider_interaction_reference',
        'provider_request_reference',
        'provider_result_code',
        'provider_result_message',
        'failure_code',
        'failure_message',
        'queued_at',
        'submitted_at',
        'completed_at',
        'created_at',
        'updated_at',
        'version',
      ];
      for (final field in expected) {
        expect(
          attemptsTable,
          contains(field),
          reason: 'delivery_attempts missing $field',
        );
      }
      expect(attemptsTable, contains('invoice_delivery_id'));
      expect(attemptsTable, contains('provider_interaction_reference'));
      expect(attemptsTable, contains('provider_request_reference'));
      expect(attemptsTable, contains('version bigint not null default 0'));
    });

    test('uses attempt status checks and nullable result fields', () {
      expect(
        attemptsTable,
        contains(
          "status in ('QUEUED','SUBMITTED','SUCCEEDED','FAILED','UNKNOWN')",
        ),
      );
      expect(attemptsTable, contains('provider_result_message text null'));
      expect(attemptsTable, contains('failure_message text null'));
      expect(attemptsTable, contains('submitted_at timestamptz null'));
      expect(attemptsTable, contains('completed_at timestamptz null'));
      expect(
        attemptsTable,
        contains('unique (tenant_id, invoice_delivery_id, attempt_no)'),
      );
    });
  });

  group('indexes, RLS, and immutable recipient semantics', () {
    test(
      'creates partial unique indexes for INITIAL_SEND and active locks',
      () {
        expect(sql, contains('delivery_intent = \'INITIAL_SEND\''));
        expect(sql, contains("status in ('PROCESSING','UNKNOWN')"));
        expect(sql, contains("status in ('QUEUED','SUBMITTED')"));
        expect(sql, contains('create unique index'));
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
          'alter table einvoice.delivery_attempts enable row level security',
        ),
      );
      expect(
        sql,
        contains(
          'revoke all on einvoice.invoice_deliveries from anon, authenticated',
        ),
      );
      expect(
        sql,
        contains(
          'revoke all on einvoice.delivery_attempts from anon, authenticated',
        ),
      );
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
      expect(
        sql,
        isNot(
          contains(
            'alter table einvoice.delivery_attempts add column if not exists is_simulated',
          ),
        ),
      );
    });

    test('does not copy provider/raw/recipient text into message columns', () {
      expect(sql, isNot(contains('provider_result_message =')));
      expect(sql, isNot(contains('failure_message = v_')));
      expect(sql, isNot(contains('exception_message')));
      expect(sql, isNot(contains('http_body')));
    });
  });
}
