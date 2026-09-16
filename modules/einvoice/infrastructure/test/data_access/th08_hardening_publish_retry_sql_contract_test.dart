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

String _readDraft(String fileName) {
  return File(
    '${_repoRoot().path}/supabase/migrations/_drafts/$fileName',
  ).readAsStringSync();
}

String _extractFunction(String sql, String signaturePrefix) {
  final start = sql.indexOf(signaturePrefix);
  if (start == -1) {
    throw StateError('Missing function: $signaturePrefix');
  }
  final end = sql.indexOf('\$\$;', start);
  if (end == -1) {
    throw StateError('Missing function terminator for: $signaturePrefix');
  }
  return sql.substring(start, end + 3);
}

void main() {
  group('th08_hardening_publish_retry — draft 020', () {
    late String sql;
    late String retryFn;
    late String claimFn;
    late String failureFn;
    late String issuanceSchemaSql;
    late String successFn;

    setUpAll(() {
      sql = _readDraft('020_einvoice_misa_publish_retry_policy.sql');
      retryFn = _extractFunction(
        sql,
        'create or replace function einvoice.record_retryable_provider_publish_rejection(',
      );
      claimFn = _extractFunction(
        sql,
        'create or replace function einvoice.claim_issuance_reconciliation_case(',
      );
      issuanceSchemaSql = _readDraft(
        '007_einvoice_issuance_schema_and_publish_rpcs.sql',
      );
      failureFn = _extractFunction(
        issuanceSchemaSql,
        'create or replace function einvoice.record_issuance_failure(',
      );
      successFn = _extractFunction(
        issuanceSchemaSql,
        'create or replace function einvoice.record_issuance_success(',
      );
    });

    test('declares Touches header for retry RPC and claim patch', () {
      expect(
        sql,
        contains(
          '-- Touches: einvoice.record_retryable_provider_publish_rejection, einvoice.claim_issuance_reconciliation_case',
        ),
      );
    });

    test('retry RPC persists attempt number, next-at and provider code', () {
      expect(retryFn, contains('provider_publish_retry_count'));
      expect(retryFn, contains('next_provider_publish_retry_at'));
      expect(retryFn, contains('last_provider_publish_code'));
      expect(retryFn, contains("set status = 'PREPARING'"));
      expect(retryFn, contains('internal_commands'));
    });

    test('issuance attempt schema owns durable retry metadata', () {
      expect(
        issuanceSchemaSql,
        contains('provider_publish_retry_count integer not null default 0'),
      );
      expect(
        issuanceSchemaSql,
        contains('next_provider_publish_retry_at timestamptz null'),
      );
      expect(
        issuanceSchemaSql,
        contains('last_provider_publish_code varchar(100) null'),
      );
      expect(sql, isNot(contains('alter table einvoice.issuance_attempts')));
    });

    test('successful terminal result clears the pending retry schedule', () {
      expect(successFn, contains('next_provider_publish_retry_at = null'));
    });

    test('retry RPC caps at three attempts then fails closed', () {
      expect(retryFn, contains('if v_next_retry_count > 3'));
      expect(retryFn, contains('einvoice.record_issuance_failure('));
      expect(failureFn, contains("settled_result = 'FAILED'"));
      expect(failureFn, contains("'einvoice.issuance.failed'"));
    });

    test('retry identity is the source provider command, not attempt id', () {
      expect(retryFn, contains('p_source_command_id uuid'));
      expect(retryFn, contains('ic.source_event_id = p_source_command_id'));
      expect(retryFn, contains('source_event_id,\n    enqueued_at'));
      expect(retryFn, contains('p_source_command_id,\n    now() + v_delay'));
      expect(retryFn, isNot(contains('p_attempt_id,\n    now() + v_delay')));
    });

    test('retry enqueue targets the existing partial dedup index', () {
      expect(
        retryFn,
        contains(
          'on conflict (tenant_id, source_event_id, command_type)\n'
          '  where source_event_id is not null do nothing',
        ),
      );
    });

    test('retry enqueue only writes columns owned by internal_commands', () {
      expect(
        retryFn,
        isNot(contains('created_at')),
        reason: 'einvoice.internal_commands has no created_at column',
      );
    });

    test('retry backoff is 5 seconds then at least 30 seconds', () {
      expect(retryFn, contains('when v_next_retry_count = 1 then 5'));
      expect(retryFn, contains('else 30'));
    });

    test('claim reconciliation returns reason_code for poll routing', () {
      expect(claimFn, contains('reconciliation_reason_code varchar(100)'));
      expect(claimFn, contains('v_case.reason_code'));
      expect(claimFn, contains('v_attempt.invoice_series'));
      expect(claimFn, isNot(contains('provider_result_snapshot')));
    });

    test('drops the old claim RPC before changing its OUT row type', () {
      const dropSignature =
          'drop function if exists einvoice.claim_issuance_reconciliation_case(uuid, uuid, varchar);';
      const createSignature =
          'create or replace function einvoice.claim_issuance_reconciliation_case(';

      expect(sql, contains(dropSignature));
      expect(
        sql.indexOf(dropSignature),
        lessThan(sql.indexOf(createSignature)),
        reason:
            'PostgreSQL requires DROP FUNCTION before changing RETURNS TABLE.',
      );
    });
  });
}
