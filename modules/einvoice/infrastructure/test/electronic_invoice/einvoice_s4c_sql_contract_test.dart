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
  final revoke = sql.indexOf('revoke all on function', start);
  final nextCreate = sql.indexOf(
    '\ncreate or replace function',
    start + signaturePrefix.length,
  );
  final endCandidates = [
    if (revoke > start) revoke,
    if (nextCreate > start) nextCreate,
    sql.length,
  ]..sort();
  return sql.substring(start, endCandidates.first);
}

void main() {
  late String sql;
  late String requestFn;
  late String recordObservationFn;
  late String getLatestFn;
  late String startInteractionFn;
  late String finalizeInteractionFn;

  setUpAll(() {
    final draft = File(
      '${_repoRoot().path}/supabase/migrations/_drafts/'
      '012_einvoice_provider_observations_rpcs.sql',
    );
    expect(draft.existsSync(), isTrue);
    sql = draft.readAsStringSync();
    requestFn = _extractFunction(
      sql,
      'create or replace function einvoice.request_provider_observation_refresh(',
    );
    recordObservationFn = _extractFunction(
      sql,
      'create or replace function einvoice.record_provider_observation(',
    );
    getLatestFn = _extractFunction(
      sql,
      'create or replace function einvoice.get_latest_provider_observation(',
    );
    startInteractionFn = _extractFunction(
      sql,
      'create or replace function einvoice.start_provider_interaction(',
    );
    finalizeInteractionFn = _extractFunction(
      sql,
      'create or replace function einvoice.record_provider_interaction_result(',
    );
  });

  group('S4c draft header and observation schema', () {
    test('declares frozen Touches set without observation seeder', () {
      expect(sql, contains('-- Intent: einvoice_s4c_provider_observations'));
      expect(
        sql,
        contains(
          '-- Touches: _provider_observation_command_id, get_latest_provider_observation, load_provider_observation_context, record_provider_interaction_result, record_provider_observation, request_provider_observation_refresh, start_provider_interaction',
        ),
      );
      expect(sql, isNot(contains('seed_due_provider_observation_commands')));
      expect(
        sql,
        isNot(
          matches(
            RegExp(
              r'select\s+.*from\s+einvoice\.electronic_invoices\s+where\s+tenant_id',
            ),
          ),
        ),
      );
    });

    test(
      'observation table references interaction without correlation_id column',
      () {
        final tableStart = sql.indexOf(
          'create table if not exists einvoice.invoice_provider_observations',
        );
        expect(tableStart, greaterThanOrEqualTo(0));
        final tableEnd = sql.indexOf(');', tableStart);
        final tableSql = sql.substring(tableStart, tableEnd);
        expect(
          tableSql,
          contains('provider_interaction_reference uuid not null'),
        );
        expect(tableSql, isNot(contains('correlation_id')));
        expect(tableSql, isNot(contains('updated_at')));
      },
    );
  });

  group('S4c trigger-scoped command identity', () {
    test('request uses triggerId dedupe without UTC date in key', () {
      expect(requestFn, contains("'provider_observation:'"));
      expect(requestFn, contains('p_trigger_id::text'));
      expect(requestFn, isNot(contains('current_date')));
      expect(requestFn, isNot(contains('date_trunc')));
      expect(requestFn, contains('einvoice.poll_provider_observation'));
      expect(requestFn, contains('on conflict (id) do nothing'));
    });

    test('command id helper hashes tenant invoice and discriminator', () {
      expect(
        sql,
        contains(
          'create or replace function einvoice._provider_observation_command_id(',
        ),
      );
      expect(sql, contains('sha256'));
    });
  });

  group('S4c interaction audit and observation record', () {
    test('start interaction validates direction and tenant connection', () {
      expect(startInteractionFn, contains("'OUTBOUND', 'INBOUND_CALLBACK'"));
      expect(startInteractionFn, contains('provider_connections'));
      expect(startInteractionFn, contains('correlation_id = p_correlation_id'));
      expect(startInteractionFn, contains("'STARTED'"));
    });

    test(
      'finalize interaction compare-and-sets version and handles conflict',
      () {
        expect(finalizeInteractionFn, contains('p_expected_version'));
        expect(finalizeInteractionFn, contains("'COMPLETED'"));
        expect(finalizeInteractionFn, contains('INTERACTION_RESULT_CONFLICT'));
        expect(finalizeInteractionFn, contains("'TIMEOUT'"));
      },
    );

    test(
      'record observation validates details and enqueues attention outbox',
      () {
        expect(
          recordObservationFn,
          contains('_validate_observation_details_snapshot'),
        );
        expect(
          recordObservationFn,
          contains('on conflict (tenant_id, deduplication_key) do nothing'),
        );
        expect(recordObservationFn, contains('latest_provider_state_code'));
        expect(recordObservationFn, contains('last_provider_observed_at'));
        expect(recordObservationFn, contains("'NOT_FOUND', 'MISMATCH'"));
        expect(
          recordObservationFn,
          contains('einvoice.provider_observation_attention_required'),
        );
        expect(
          recordObservationFn,
          contains("'attention:' || p_deduplication_key"),
        );
        expect(recordObservationFn, isNot(contains('invoice_issuances')));
        expect(recordObservationFn, isNot(contains('issuance_attempts')));
      },
    );

    test('get latest observation joins interaction for correlation_id', () {
      expect(getLatestFn, contains('iam.has_permission'));
      expect(getLatestFn, contains('sales.can_access_sales_order'));
      expect(getLatestFn, contains('provider_interaction_records pir'));
      expect(getLatestFn, contains('pir.correlation_id'));
    });
  });
}
