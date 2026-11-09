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

