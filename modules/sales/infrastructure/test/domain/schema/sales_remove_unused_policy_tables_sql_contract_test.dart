import 'dart:io';

import 'package:test/test.dart';

const removedTables = <String>[
  'sales.return_exchange_reason_policy',
  'sales.return_exchange_condition_policy',
  'sales.return_exchange_reservation_refs',
  'sales.checkout_store_policies',
];

const iamOwners = <String>[
  'supabase/migrations/20260827001_iam_active_store_context_group_a.sql',
  'supabase/migrations/20260830001_iam_active_store_context_group_a.sql',
];

const schemaOwners = <String>[
  'supabase/migrations/20260827005_sales_rebuild_schema.sql',
  'supabase/migrations/20260830005_sales_rebuild_schema.sql',
];

const checkoutOwners = <String>[
  'supabase/migrations/20260827008_sales_checkout_rpcs.sql',
  'supabase/migrations/20260830008_sales_checkout_rpcs.sql',
];

const sessionOwners = <String>[
  'supabase/migrations/20260827012_sales_return_exchange_session_rpcs.sql',
  'supabase/migrations/20260830012_sales_return_exchange_session_rpcs.sql',
];

const confirmationOwners = <String>[
  'supabase/migrations/20260827014_sales_return_exchange_confirmation_rpcs.sql',
  'supabase/migrations/20260830014_sales_return_exchange_confirmation_rpcs.sql',
  'supabase/migrations/20260904001_sales_normalize_outbox_and_commands.sql',
];

const expectedSignatures = <String, String>{
  'sales.get_return_exchange_form_policy':
      'create or replace function sales.get_return_exchange_form_policy( '
      'query_id text, tenant_id uuid, actor_id uuid ) returns jsonb',
  'sales.start_return_exchange':
      'create or replace function sales.start_return_exchange( command_id text, '
      'tenant_id uuid, actor_id uuid, sales_order_id uuid, entry_source text, '
      'lines jsonb, idempotency_key text, payload_hash text, correlation_id text, '
      'causation_id text default null, expected_source_version integer default null, '
      "reference_decision jsonb default '{}'::jsonb, "
      'reason text default null ) returns jsonb',
  'sales._get_return_exchange_context':
      'create or replace function sales._get_return_exchange_context( tenant_id uuid, '
      'actor_id uuid, return_exchange_id uuid ) returns jsonb',
  'sales.update_return_exchange':
      'create or replace function sales.update_return_exchange( command_id text, '
      'tenant_id uuid, actor_id uuid, return_exchange_id uuid, lines jsonb, '
      'idempotency_key text, payload_hash text, correlation_id text, '
      'causation_id text default null, expected_version integer default null, '
      "reference_decision jsonb default '{}'::jsonb, "
      'reason text default null ) returns jsonb',
  'iam.bootstrap_owner':
      "create or replace function iam.bootstrap_owner(p_tenant_name text default 'My Store') "
      'returns uuid',
  'sales.confirm_return_exchange':
      'create or replace function sales.confirm_return_exchange( command_id text, '
      'tenant_id uuid, actor_id uuid, return_exchange_id uuid, idempotency_key text, '
      'payload_hash text, correlation_id text, causation_id text default null, '
      "expected_version integer default null, reference_decision jsonb default '{}'::jsonb, "
      "payment_settled_now_minor bigint default null, payment_method text default 'cash', "
      'payment_due_date date default null ) returns jsonb',
};

void main() {
  test('promoted baselines no longer create or reference retired tables', () {
    for (final path in [
      ...iamOwners,
      ...schemaOwners,
      ...checkoutOwners,
      ...sessionOwners,
      ...confirmationOwners,
    ]) {
      final sql = readRepo(path);
      for (final table in removedTables) {
        expect(sql, isNot(contains(table)), reason: '$path still references $table');
      }
    }
  });

  test('six RPC signatures stay frozen on their promoted owners', () {
    final currentOwners = <String, String>{
      'sales.get_return_exchange_form_policy': sessionOwners.last,
      'sales.start_return_exchange': sessionOwners.last,
      'sales._get_return_exchange_context': sessionOwners.last,
      'sales.update_return_exchange': sessionOwners.last,
      'iam.bootstrap_owner': iamOwners.last,
      'sales.confirm_return_exchange': confirmationOwners.last,
    };

    for (final entry in currentOwners.entries) {
      expect(
        functionSignature(functionBody(readRepo(entry.value), entry.key)),
        expectedSignatures[entry.key],
        reason: entry.key,
      );
    }
  });

  test('policy and context responses preserve empty-array contracts', () {
    for (final path in sessionOwners) {
      final sql = readRepo(path);
      final policy = functionBody(sql, 'sales.get_return_exchange_form_policy');
      expect(policy, contains("'reasons', '[]'::jsonb"));
      expect(policy, contains("'conditions', '[]'::jsonb"));
      expect(policy, contains('PERMISSION_DENIED'));

      final context = functionBody(sql, 'sales._get_return_exchange_context');
      expect(context, contains("'reservationIds', '[]'::jsonb"));
      expect(context, contains('DATA_SCOPE_DENIED'));

      for (final name in [
        'sales.start_return_exchange',
        'sales.update_return_exchange',
      ]) {
        final body = functionBody(sql, name);
        expect(body, contains('_complete_sales_idempotency'));
        expect(body, contains('reference_decision'));
      }
    }
  });

  test('confirmation keeps source, valuation, version and lifecycle guards', () {
    for (final path in confirmationOwners) {
      final confirm = functionBody(
        readRepo(path),
        'sales.confirm_return_exchange',
      );
      expect(confirm, contains('valuation_details'), reason: path);
      expect(confirm, contains('STALE_VERSION'), reason: path);
      expect(confirm, contains('RETURN_EXCHANGE_BLOCKED'), reason: path);
      expect(confirm, contains('sales.return_exchange_valuations'), reason: path);
      expect(confirm, contains("rl.line_role = 'returned'"), reason: path);
      expect(
        confirm,
        contains(
          'rl.original_sales_order_line_id is null and '
          'rl.source_exchange_line_id is null',
        ),
        reason: path,
      );
      expect(confirm, contains("rl.line_role = 'exchange'"), reason: path);
    }
  });

  test('duplicate bootstrap generations remain synchronized', () {
    expect(readRepo(iamOwners.first), readRepo(iamOwners.last));
    expect(readRepo(schemaOwners.first), readRepo(schemaOwners.last));
    expect(readRepo(checkoutOwners.first), readRepo(checkoutOwners.last));
    expect(readRepo(sessionOwners.first), readRepo(sessionOwners.last));
    expect(
      readRepo(confirmationOwners.first),
      readRepo(confirmationOwners[1]),
    );
  });
}

String readRepo(String relative) {
  var dir = Directory.current.absolute;
  while (true) {
    final file = File('${dir.path}/$relative');
    if (file.existsSync()) return file.readAsStringSync();
    final parent = dir.parent;
    if (parent.path == dir.path) throw StateError('Missing $relative');
    dir = parent;
  }
}

String functionBody(String sql, String name) {
  final start = sql.indexOf('create or replace function $name(');
  if (start < 0) throw StateError('Missing $name');
  final end = sql.indexOf('\n\$\$;', start);
  if (end < 0) throw StateError('Missing terminator $name');
  return sql.substring(start, end + 4);
}

String functionSignature(String body) {
  final match = RegExp(r'\breturns\b', caseSensitive: false).firstMatch(body);
  if (match == null) throw StateError('Missing returns');
  final end = body.indexOf('\n', match.start);
  if (end < 0) throw StateError('Missing signature end');
  return body.substring(0, end).trim().replaceAll(RegExp(r'\s+'), ' ');
}
