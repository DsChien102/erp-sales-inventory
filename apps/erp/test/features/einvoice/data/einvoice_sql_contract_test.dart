import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _appEinvoiceRpcNames = [
  'connect_provider',
  'disconnect_provider',
  'get_automation_policy',
  'get_configuration_readiness',
  'get_electronic_invoice_detail',
  'get_invoice_delivery_history',
  'get_invoice_documents',
  'get_invoice_preview',
  'get_issuance_attempt_status',
  'get_issuance_profile',
  'get_issuance_readiness',
  'get_order_invoice_projection',
  'get_provider_connection_screen',
  'get_send_invoice_sheet_context',
  'issue_invoice',
  'list_provider_templates',
  'reconnect_provider',
  'request_invoice_document',
  'request_invoice_preview',
  'request_official_invoice_view',
  'retry_issuance',
  'send_electronic_invoice',
  'set_default_issuance_configuration',
  'update_automation_policy',
];

void main() {
  group('kept', () {
    test('keeps every RPC the app calls', () {
      final sql = _allMigrationsSql();
      expect(_appEinvoiceRpcNames.length, 24);
      for (final rpc in _appEinvoiceRpcNames) {
        expect(
          _einvoiceDefines(sql, rpc),
          isTrue,
          reason: 'Expected einvoice.$rpc to be defined in migrations.',
        );
      }
    });

    test('app RPC list matches repositories', () {
      final repoRoot = _findRepoRoot();
      final dataDir = Directory(
        '${repoRoot.path}/apps/erp/lib/features/einvoice/data',
      );
      final dartFiles = dataDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final rpcCalls = <String>{};
      final pattern = RegExp(r"'einvoice',\s*'([a-z_]+)'", multiLine: true);
      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        for (final match in pattern.allMatches(content)) {
          rpcCalls.add(match.group(1)!);
        }
      }

      expect(rpcCalls, equals(_appEinvoiceRpcNames.toSet()));
    });

    test('keeps every RPC the processor calls', () {
      final repoRoot = _findRepoRoot();
      final procDir = Directory(
        '${repoRoot.path}/supabase/functions/einvoice-processor',
      );
      final tsFiles = procDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.ts') && !f.path.endsWith('_test.ts'));

      final processorCalls = <String>{};
      final pattern = RegExp(r"(?:\.rpc|#call)\(\s*'([a-z_]+)'");
      for (final file in tsFiles) {
        final content = file.readAsStringSync();
        for (final match in pattern.allMatches(content)) {
          processorCalls.add(match.group(1)!);
        }
      }

      expect(processorCalls.length, 38);
      final sql = _allMigrationsSql();
      for (final rpc in processorCalls) {
        expect(
          _einvoiceDefines(sql, rpc),
          isTrue,
          reason: 'Expected einvoice.$rpc (processor) to be defined in migrations.',
        );
      }
    });

    test('keeps outbox log writers', () {
      final repoRoot = _findRepoRoot();
      final dir = Directory('${repoRoot.path}/supabase/migrations');
      final files = dir
          .listSync()
          .whereType<File>()
          .where(
            (f) =>
                f.path.endsWith('.sql') &&
                !f.path.contains('_drafts') &&
                !f.uri.pathSegments.last.startsWith('20261031002'),
          );

      var count = 0;
      final pattern = RegExp(r'einvoice\.enqueue_outbox_message\(');
      for (final f in files) {
        final content = f.readAsStringSync();
        count += pattern.allMatches(content).length;
      }

      expect(count, equals(12));
      final sql = _allMigrationsSql();
      expect(_einvoiceDefines(sql, 'enqueue_outbox_message'), isTrue);
    });

    test('outbox writers use only the 5 log columns', () {
      final sql = _allMigrationsSql();
      const allowed = {
        'id',
        'tenant_id',
        'event_type',
        'payload',
        'occurred_at',
      };
      final pattern = RegExp(
        r'insert into einvoice\.outbox_messages\s*\(([^)]*)\)',
        caseSensitive: false,
      );
      final matches = pattern.allMatches(sql).toList();
      expect(matches, isNotEmpty);

      for (final match in matches) {
        final cols = match
            .group(1)!
            .split(',')
            .map((c) => c.trim().toLowerCase())
            .toSet();
        expect(
          allowed.containsAll(cols),
          isTrue,
          reason: 'Found unexpected column in outbox insert: $cols',
        );
      }

      final migration2 = _migration('20261031002');
      expect(
        migration2.contains('id, tenant_id, event_type, payload, occurred_at'),
        isTrue,
      );
    });

    test('nobody reads outbox or inbox', () {
      final sql = _allMigrationsSql();
      expect(sql.contains('from einvoice.outbox_messages'), isFalse);
      expect(sql.contains('join einvoice.outbox_messages'), isFalse);
      expect(sql.contains('einvoice.inbox_messages'), isFalse);

      final repoRoot = _findRepoRoot();
      final procDir = Directory(
        '${repoRoot.path}/supabase/functions/einvoice-processor',
      );
      final tsFiles = procDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.ts'));

      for (final f in tsFiles) {
        final content = f.readAsStringSync();
        expect(content.contains('outbox_messages'), isFalse);
        expect(content.contains('inbox_messages'), isFalse);
      }
    });
  });

  group('removed', () {
    test('einvoice no longer installs messaging', () {
      final sql = _allMigrationsSql();
      expect(sql.contains("install_module_messaging('einvoice')"), isFalse);

      final m = _migration('20261031002');
      expect(m.contains('platform.install_module_messaging'), isFalse);
      expect(m.contains('messaging_module_registry'), isFalse);
      expect(m.contains('rebuild_messaging_backlog_stats_view'), isFalse);
    });

    test('einvoice has no inbox or outbox queue', () {
      final m = _migration('20261031002');
      expect(m.contains('inbox_messages'), isFalse);
      expect(m.contains('receive_integration_event'), isFalse);
      expect(m.contains('claim_outbox_batch'), isFalse);
      expect(m.contains('complete_outbox_message'), isFalse);
      expect(m.contains('fail_outbox_message'), isFalse);
      expect(m.contains('claim_inbox_batch'), isFalse);
      expect(m.contains('complete_inbox_message'), isFalse);
      expect(m.contains('fail_inbox_message'), isFalse);
    });

    test('creates einvoice queue directly', () {
      final m = _migration('20261031002');

      // (1) internal_commands table with 12 columns
      final cmdStart = m.indexOf('create table if not exists einvoice.internal_commands (');
      expect(cmdStart, greaterThanOrEqualTo(0), reason: 'Missing table einvoice.internal_commands');
      final cmdEnd = m.indexOf(');', cmdStart);
      final cmdBlock = m.substring(cmdStart, cmdEnd);
      for (final col in const [
        'id uuid primary key',
        'tenant_id uuid not null',
        'command_type text not null',
        'payload jsonb not null',
        'source_event_id uuid null',
        'enqueued_at timestamptz not null default now()',
        'processed_at timestamptz null',
        'failed_at timestamptz null',
        'error text null',
        'retry_count int not null default 0',
        'claimed_at timestamptz null',
        'claim_token uuid null',
      ]) {
        expect(cmdBlock.contains(col), isTrue, reason: 'internal_commands missing $col');
      }

      // (2) 2 indexes
      expect(m.contains('internal_commands_pending_tenant_idx'), isTrue);
      expect(m.contains('internal_commands_source_dedup_idx'), isTrue);

      // (3) outbox_messages table with 5 columns
      final outboxStart = m.indexOf('create table if not exists einvoice.outbox_messages (');
      expect(outboxStart, greaterThanOrEqualTo(0), reason: 'Missing table einvoice.outbox_messages');
      final outboxEnd = m.indexOf(');', outboxStart);
      final outboxBlock = m.substring(outboxStart, outboxEnd);
      for (final col in const [
        'id uuid primary key',
        'tenant_id uuid not null',
        'event_type text not null',
        'payload jsonb not null',
        'occurred_at timestamptz not null default now()',
      ]) {
        expect(outboxBlock.contains(col), isTrue, reason: 'outbox_messages missing $col');
      }
      expect(outboxBlock.contains('processed_at'), isFalse);
      expect(outboxBlock.contains('claim_token'), isFalse);

      // (4) 5 functions defined in this migration
      for (final fn in const [
        'enqueue_outbox_message',
        'enqueue_internal_command',
        'claim_internal_commands_batch',
        'complete_internal_command',
        'fail_internal_command',
      ]) {
        expect(_definesFn(m, 'einvoice', fn), isTrue, reason: 'Migration missing function einvoice.$fn');
      }

      // (5) 5 grant execute signatures to service_role
      for (final sig in const [
        'einvoice.enqueue_outbox_message(uuid, text, jsonb, uuid, timestamptz)',
        'einvoice.enqueue_internal_command(uuid, text, jsonb, uuid, uuid)',
        'einvoice.claim_internal_commands_batch(uuid, int)',
        'einvoice.complete_internal_command(uuid, uuid, uuid)',
        'einvoice.fail_internal_command(uuid, uuid, uuid, text)',
      ]) {
        expect(
          m.contains('grant execute on function $sig to service_role'),
          isTrue,
          reason: 'Missing grant execute for $sig',
        );
      }

      // (6) permissions
      expect(m.contains('revoke all on all tables in schema einvoice from public, anon, authenticated'), isTrue);
      expect(m.contains('grant usage on schema einvoice to service_role'), isTrue);
      expect(m.contains('grant usage on schema einvoice to authenticated'), isTrue);
    });

    test('drops renew_publish_series_lease', () {
      final sql = _allMigrationsSql();
      expect(_definesFn(sql, 'einvoice', 'renew_publish_series_lease'), isFalse);
      expect(sql.contains('einvoice.renew_publish_series_lease'), isFalse);

      final repoRoot = _findRepoRoot();
      final regFile = File('${repoRoot.path}/supabase/migrations/REGISTRY.yaml');
      final regContent = regFile.readAsStringSync();
      expect(regContent.contains('renew_publish_series_lease'), isFalse);
    });
  });
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate Mosaic Retail workspace root');
    }
    current = parent;
  }
  return current;
}

String _allMigrationsSql() {
  final repoRoot = _findRepoRoot();
  final dir = Directory('${repoRoot.path}/supabase/migrations');
  final files =
      dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.sql') && !f.path.contains('_drafts'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return files.map((f) => f.readAsStringSync()).join('\n');
}

bool _definesFn(String sql, String schema, String name) {
  return RegExp(
    r'create\s+(or\s+replace\s+)?function\s+' +
        schema +
        r'\.' +
        name +
        r'\s*\(',
    caseSensitive: false,
  ).hasMatch(sql);
}

String _migration(String prefix) {
  final repoRoot = _findRepoRoot();
  final dir = Directory('${repoRoot.path}/supabase/migrations');
  final matches =
      dir
          .listSync()
          .whereType<File>()
          .where(
            (f) =>
                f.uri.pathSegments.last.startsWith(prefix) &&
                f.path.endsWith('.sql'),
          )
          .toList();
  if (matches.length != 1) {
    fail(
      'Expected exactly one migration file with prefix $prefix, found ${matches.length}',
    );
  }
  return matches.single.readAsStringSync();
}

const _installedQueueFns = {
  'enqueue_outbox_message',
  'claim_outbox_batch',
  'complete_outbox_message',
  'fail_outbox_message',
  'receive_integration_event',
  'claim_inbox_batch',
  'complete_inbox_message',
  'fail_inbox_message',
  'enqueue_internal_command',
  'claim_internal_commands_batch',
  'complete_internal_command',
  'fail_internal_command',
};

bool _einvoiceDefines(String sql, String name) {
  if (_definesFn(sql, 'einvoice', name)) return true;
  final migration2 = _migration('20261031002');
  return migration2.contains(
        "select platform.install_module_messaging('einvoice')",
      ) &&
      _installedQueueFns.contains(name);
}

