import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Einvoice refactor gói 4 (gửi hoá đơn).
void main() {
  final deliverySql = _readDraft(
    '013_einvoice_delivery_schema_and_start_rpcs.sql',
  );
  final resultSql = _readDraft(
    '014_einvoice_delivery_results_and_projection_rpcs.sql',
  );
  final reconSql = _readDraft(
    '015_einvoice_delivery_reconciliation_rpcs.sql',
  );

  group('Task 1 — bảng gửi và bắt đầu gửi', () {
    test('one delivery row carries the technical retry state', () {
      final table = _createTable(deliverySql, 'einvoice.invoice_deliveries');
      for (final column in const [
        'retry_count int not null default 0',
        'provider_connection_id uuid not null',
        'provider_request_reference text',
        'failure_source text',
        'recipient_snapshot_schema_version integer not null default 1',
        'submitted_at timestamptz',
        "check (status in ('QUEUED', 'SUBMITTED', 'SUCCEEDED', 'FAILED', 'UNKNOWN'))",
        'unique (tenant_id, id)',
        'references einvoice.provider_connections (tenant_id, id)',
      ]) {
        expect(table, contains(column), reason: column);
      }
      for (final gone in const [
        'channel',
        'intent_hash',
        'trigger_type',
        'provider_result_code',
        'provider_result_message',
        'updated_at',
        'started_at',
        'PROCESSING',
      ]) {
        expect(table, isNot(contains(gone)), reason: gone);
      }
    });

    test('013 no longer knows attempts, intent hashes or PROCESSING rows', () {
      expect(deliverySql, isNot(contains('delivery_attempts')));
      expect(deliverySql, isNot(contains('intent_hash')));
      expect(deliverySql, isNot(contains('trigger_type')));
      expect(deliverySql, isNot(contains("d.status = 'PROCESSING'")));
      expect(deliverySql, contains("where status in ('QUEUED','SUBMITTED')"));
    });

    test('public status hides the technical sub-states', () {
      final body = _lastFunctionBlock(
        deliverySql,
        'einvoice._delivery_public_status',
      );
      expect(body, contains("in ('QUEUED', 'SUBMITTED') then 'PROCESSING'"));
      final projection = _lastFunctionBlock(
        deliverySql,
        'einvoice._delivery_display_projection',
      );
      expect(projection, contains("array['QUEUED', 'SUBMITTED']"));
    });

    test('idempotent replays compare stored fields', () {
      final manual = _lastFunctionBlock(
        deliverySql,
        'einvoice.send_electronic_invoice',
      );
      expect(manual, contains("lower(v_existing.recipient_snapshot ->> 'toEmail')"));
      expect(manual, contains('v_existing.electronic_invoice_id is distinct from'));
      final auto = _lastFunctionBlock(
        deliverySql,
        'einvoice.start_auto_delivery',
      );
      expect(auto, contains("v_existing.delivery_intent <> 'INITIAL_SEND'"));
    });

    test('start creates one queued row and a retry-addressed command', () {
      final body = _lastFunctionBlock(
        deliverySql,
        'einvoice._start_invoice_delivery',
      );
      expect(body, contains("'QUEUED'"));
      expect(body, contains('_delivery_send_command_id(v_delivery_id, 0)'));
      expect(body, contains("'retry_count', 0"));
      final commandId = _lastFunctionBlock(
        deliverySql,
        'einvoice._delivery_send_command_id',
      );
      expect(commandId, contains('p_retry_count int'));
    });

    test('worker context is addressed by delivery and retry count', () {
      final body = _lastFunctionBlock(
        deliverySql,
        'einvoice.load_delivery_attempt_context',
      );
      expect(body, contains('p_retry_count int'));
      expect(body, contains('v_delivery.retry_count <> p_retry_count'));
      expect(body, isNot(contains('p_attempt_id')));
    });

    test('history derives trigger type and start time', () {
      final body = _lastFunctionBlock(
        deliverySql,
        'einvoice.get_invoice_delivery_history',
      );
      expect(body, contains("d.initiated_by_actor_type = 'SYSTEM'"));
      expect(body, contains("'startedAt', d.created_at"));
      expect(body, contains("'status', einvoice._delivery_public_status(d.status)"));
    });

    test('reconciliation targets the delivery row', () {
      final caseTable = _createTable(
        _readDraft('007_einvoice_issuance_schema_and_publish_rpcs.sql'),
        'einvoice.invoice_reconciliation_cases',
      );
      expect(
        caseTable,
        contains("target_type in ('ISSUANCE_ATTEMPT', 'INVOICE_DELIVERY')"),
      );
      expect(caseTable, isNot(contains('target_retry_count')));
    });
  });

  group('Task 2 — worker gửi thư', () {
    test('014 no longer knows attempts or interaction references', () {
      expect(resultSql, isNot(contains('delivery_attempts')));
      expect(resultSql, isNot(contains('DELIVERY_ATTEMPT')));
      expect(resultSql, isNot(contains('p_attempt_id')));
      expect(resultSql, isNot(contains('interaction_reference')));
      expect(resultSql, isNot(contains("'PROCESSING'")));
    });

    test('dispatch barrier is QUEUED to SUBMITTED on the current try', () {
      final body = _lastFunctionBlock(
        resultSql,
        'einvoice.prepare_delivery_provider_call',
      );
      expect(body, contains('v_delivery.retry_count <> p_retry_count'));
      expect(body, contains("set status = 'SUBMITTED'"));
      expect(body, contains("'RECORD_UNKNOWN'"));
    });

    test('result recording: one row, one version, retry bumps the counter', () {
      final body = _lastFunctionBlock(
        resultSql,
        'einvoice.record_delivery_result',
      );
      expect(body, contains('p_retry_count int'));
      expect(body, contains('p_failure_source text'));
      expect(body, contains('v_delivery.retry_count < 2'));
      expect(body, contains('retry_count = v_delivery.retry_count + 1'));
      expect(
        body,
        contains('einvoice._delivery_send_command_id(p_delivery_id, v_delivery.retry_count + 1)'),
      );
      // Mã lệnh cố định: truyền đủ (source_event_id = null, command id).
      expect(RegExp(r'null,\s+v_cmd_id').hasMatch(body), isTrue);
      expect(body, contains("'einvoice.delivery.result_recorded'"));
      expect(body, contains('einvoice._delivery_public_status(v_delivery.status)'));
    });

    test('reconciliation case opens against the delivery in one place', () {
      final helper = _lastFunctionBlock(
        resultSql,
        'einvoice._open_delivery_reconciliation_case',
      );
      expect(helper, contains("'INVOICE_DELIVERY'"));
      expect(
        'perform einvoice._open_delivery_reconciliation_case('
            .allMatches(resultSql)
            .length,
        2, // record_delivery_result + record_delivery_command_dead_letter
      );
    });

    test('dead letter is addressed by retry count', () {
      final body = _lastFunctionBlock(
        resultSql,
        'einvoice.record_delivery_command_dead_letter',
      );
      expect(body, contains('p_retry_count int'));
      expect(body, contains("failure_source = 'INTERNAL'"));
    });
  });

  group('Task 3 — đối soát lần gửi', () {
    test('015 works on the delivery row', () {
      expect(reconSql, isNot(contains('delivery_attempts')));
      expect(reconSql, isNot(contains('DELIVERY_ATTEMPT')));
      expect(reconSql, isNot(contains('attempt_id')));
      expect(reconSql, contains("v_case.target_type is distinct from 'INVOICE_DELIVERY'"));
    });

    test('check no longer takes an interaction reference', () {
      final body = _lastFunctionBlock(
        reconSql,
        'einvoice.record_delivery_reconciliation_check',
      );
      expect(body, isNot(contains('p_interaction_reference')));
      expect(body, isNot(contains('latest_provider_interaction_reference')));
      expect(body, contains("failure_source = 'PROVIDER'"));
    });
  });

  group('Task 4 — xoá nhật ký gọi MISA', () {
    test('no draft mentions attempts rows or the interaction log', () {
      for (final draft in _allDrafts()) {
        final sql = draft.readAsStringSync();
        for (final gone in const [
          'delivery_attempts',
          'provider_interaction_records',
          'start_provider_interaction',
          'record_provider_interaction_result',
        ]) {
          expect(sql, isNot(contains(gone)), reason: '${draft.path}: $gone');
        }
      }
    });

    test('no einvoice lib source references the interaction log', () {
      final root = '${_findRepoRoot().path}/modules/einvoice';
      final libFiles = Directory(root)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => f.path.contains('/lib/'));
      for (final file in libFiles) {
        expect(
          file.readAsStringSync(),
          isNot(contains('ProviderInteraction')),
          reason: file.path,
        );
      }
    });
  });
}

Iterable<File> _allDrafts() => Directory(
  '${_findRepoRoot().path}/supabase/migrations/_drafts',
).listSync().whereType<File>().where((f) => f.path.endsWith('.sql'));

String _readDraft(String fileName) => File(
  '${_findRepoRoot().path}/supabase/migrations/_drafts/$fileName',
).readAsStringSync();

/// Thân `create table if not exists <qualifiedName> (` … `\n);` trong [sql].
String _createTable(String sql, String qualifiedName) {
  final start = sql.indexOf('create table if not exists $qualifiedName (');
  if (start < 0) {
    throw StateError('$qualifiedName not found');
  }
  return sql.substring(start, sql.indexOf('\n);', start));
}

/// `create or replace function <qualifiedName>(` … `$$;` cuối cùng trong [sql].
String _lastFunctionBlock(String sql, String qualifiedName) {
  final start = sql.lastIndexOf('create or replace function $qualifiedName(');
  if (start < 0) {
    throw StateError('$qualifiedName not found');
  }
  final end = sql.indexOf(r'$$;', start);
  return sql.substring(start, end + 3);
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate Vet45 workspace root');
    }
    current = parent;
  }
  return current;
}
